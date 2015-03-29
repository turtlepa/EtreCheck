/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "VirtualMemoryCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "ByteCountFormatter.h"
#import "Model.h"
#import "Utilities.h"

// Collect virtual memory information.
@implementation VirtualMemoryCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"vm";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);

    formatter = [[ByteCountFormatter alloc] init];

    formatter.k1000 = 1024.0;
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [formatter release];
    
  [super dealloc];
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking virtual memory information", NULL)];

  NSDictionary * vminfo = [self collectVirtualMemoryInformation];
    
  [self.result appendAttributedString: [self buildTitle]];

  [self
    printVM: vminfo
    forKey: NSLocalizedString(@"Free RAM", NULL)
    indent: @"    "];
  [self
    printVM: vminfo
    forKey: NSLocalizedString(@"Used RAM", NULL)
    indent: @"    "];
  [self
    printVM: vminfo
    forKey: NSLocalizedString(@"Wired RAM", NULL)
    indent: @"        "];
  [self
    printVM: vminfo
    forKey: NSLocalizedString(@"File Cache", NULL)
    indent: @"        "];
  
  [self.result appendCR];
  
  NSUInteger GB = 1024 * 1024 * 1024;

  if(pageouts > (GB * 1))
    [self
      printVM: vminfo
      forKey: NSLocalizedString(@"Swap Used", NULL)
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red]
        }
      indent: @"    "];
  else
    [self
      printVM: vminfo
      forKey: NSLocalizedString(@"Swap Used", NULL)
      indent: @"    "];

  [self.result appendCR];

  dispatch_semaphore_signal(self.complete);
  }

// Collect virtual memory information.
- (NSDictionary *) collectVirtualMemoryInformation
  {
  NSMutableDictionary * vminfo = [NSMutableDictionary dictionary];
  
  [self collectvm_stat: vminfo];
  [self collecttop: vminfo];
  [self collectsysctl: vminfo];
  
  return vminfo;
  }

// Collect information from vm_stat.
- (void) collectvm_stat: (NSMutableDictionary *) vminfo
  {
  NSData * data = [Utilities execute: @"/usr/bin/vm_stat" arguments: nil];
  
  if(data)
    {
    NSArray * lines = [Utilities formatLines: data];
    
    NSMutableDictionary * vm_stats = [NSMutableDictionary dictionary];
    
    for(NSString * line in lines)
      {
      NSArray * parts = [line componentsSeparatedByString: @":"];
      
      if([parts count] > 1)
        {
        NSString * key = [parts objectAtIndex: 0];

        NSString * value = [parts objectAtIndex: 1];
          
        [vm_stats setObject: value forKey: key];
        }
      }

    // Format the values into something I can use.
    [vminfo addEntriesFromDictionary: [self formatVMStats: vm_stats]];
    }
  }

// Collect information from top.
- (void) collecttop: (NSMutableDictionary *) vminfo
  {
  NSArray * args = @[@"-c", @"/usr/bin/top -l 1 -stats pid,cpu,mem"];
  
  NSData * result = [Utilities execute: @"/bin/sh" arguments: args];
  
  NSArray * lines = [Utilities formatLines: result];
  
  for(NSString * line in lines)
    if([line hasPrefix: @"PhysMem: "])
      // Format the values into something I can use.
      [vminfo addEntriesFromDictionary: [self formatTop: line]];
  }

// Collect information from sysctl.
- (void) collectsysctl: (NSMutableDictionary *) vminfo
  {
  NSArray * args = @[@"-a"];
  
  NSData * data = [Utilities execute: @"/usr/sbin/sysctl" arguments: args];
  
  NSArray * lines = [Utilities formatLines: data];
  
  for(NSString * line in lines)
    if([line hasPrefix: @"vm.swapusage:"])
      // Format the values into something I can use.
      [vminfo addEntriesFromDictionary: [self formatSysctl: line]];
  }

// Format output from vm_stats into something useable.
- (NSDictionary *) formatVMStats: (NSDictionary *) vm_stats
  {
  NSString * statisticsValue =
    [vm_stats objectForKey: @"Mach Virtual Memory Statistics"];
  NSString * cachedValue = [vm_stats objectForKey: @"File-backed pages"];

  double pageSize = [self parsePageSize: statisticsValue];
  
  double cached = [cachedValue doubleValue] * pageSize;
  
  return
    @{
      NSLocalizedString(@"File Cache", NULL) :
        [NSNumber numberWithDouble: cached],
    };
  }
  
// Parse a VM page size.
- (double) parsePageSize: (NSString *) statisticsValue
  {
  NSScanner * scanner = [NSScanner scannerWithString: statisticsValue];

  double size;

  if([scanner scanDouble: & size])
    return size;

  return 4096;
  }

// Format output from top into something useable.
- (NSDictionary *) formatTop: (NSString *) line
  {
  NSScanner * scanner = [NSScanner scannerWithString: line];
  
  [scanner scanString: @"PhysMem:" intoString: NULL];
  
  NSString * usedString;
  
  [scanner
    scanUpToCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]
    intoString: & usedString];
  
  double used = [Utilities scanTopMemory: usedString];
  
  [scanner scanString: @"used (" intoString: NULL];

  NSString * wiredString;
  
  [scanner
    scanUpToCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]
    intoString: & wiredString];
  
  double wired = [Utilities scanTopMemory: wiredString];

  [scanner scanString: @"wired)," intoString: NULL];

  NSString * freeString;
  
  [scanner
    scanUpToCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]
    intoString: & freeString];
  
  double free = [Utilities scanTopMemory: freeString];
  
  [scanner scanString: @"unused." intoString: NULL];

  return
    @{
      NSLocalizedString(@"Used RAM", NULL) :
        [NSNumber numberWithDouble: used],
      NSLocalizedString(@"Wired RAM", NULL) :
        [NSNumber numberWithDouble: wired],
      NSLocalizedString(@"Free RAM", NULL) :
        [NSNumber numberWithDouble: free],
    };
  }

// Format output from sysctl into something useable.
- (NSDictionary *) formatSysctl: (NSString *) line
  {
  NSScanner * scanner = [NSScanner scannerWithString: line];
  
  [scanner scanString: @"vm.swapusage: total =" intoString: NULL];
  
  NSString * totalString;
  
  [scanner
    scanUpToCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]
    intoString: & totalString];
  
  [scanner scanString: @"used =" intoString: NULL];

  NSString * usedString;
  
  [scanner
    scanUpToCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]
    intoString: & usedString];
  
  double used = [Utilities scanTopMemory: usedString];
  
  return
    @{
      NSLocalizedString(@"Swap Used", NULL) :
        [NSNumber numberWithDouble: used]
    };
  }

// Print a VM value.
- (void) printVM: (NSDictionary *) vminfo
  forKey: (NSString *) key indent: (NSString *) indent
  {
  double value = [[vminfo objectForKey: key] doubleValue];
  
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          @"%@%@    %@\n",
          indent,
          [formatter stringFromByteCount: (unsigned long long)value],
          key]];
  }

// Print a VM value.
- (void) printVM: (NSDictionary *) vminfo
  forKey: (NSString *) key
  attributes: (NSDictionary *) attributes
  indent: (NSString *) indent
  {
  double value = [[vminfo objectForKey: key] doubleValue];
  
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          @"%@%@    %@\n",
          indent,
          [formatter stringFromByteCount: (unsigned long long)value],
          key]
    attributes: attributes];
  }

@end
