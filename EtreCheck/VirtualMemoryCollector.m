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
    
  [self printUsedVM: vminfo];
    
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

// Print a VM value.
- (void) printVM: (NSDictionary *) vminfo
  forKey: (NSString *) key indent: (NSString *) indent
  {
  [self printVM: vminfo forKey: key indent: indent extra: @""];
  }

// Print a VM value.
- (void) printVM: (NSDictionary *) vminfo
  forKey: (NSString *) key
  indent: (NSString *) indent
  extra: (NSString *) extra
  {
  double value = [[vminfo objectForKey: key] doubleValue];
  
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          @"%@%@    %@ %@\n",
          indent,
          [formatter stringFromByteCount: (unsigned long long)value],
          key,
          extra]];
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

// Print the used VM value.
- (void) printUsedVM: (NSDictionary *) vminfo
  {
  double wired =
    [[vminfo objectForKey: NSLocalizedString(@"Wired RAM", NULL)]
      doubleValue];
  double cached =
    [[vminfo objectForKey: NSLocalizedString(@"File Cache", NULL)]
      doubleValue];

  NSString * extra =
    [NSString
      stringWithFormat:
        NSLocalizedString(@"(%@ Wired - %@ Cached)", NULL),
        [formatter stringFromByteCount: (unsigned long long)wired],
        [formatter stringFromByteCount: (unsigned long long)cached]];

  [self
    printVM: vminfo
    forKey: NSLocalizedString(@"Used RAM", NULL)
    indent: @"    "
    extra: extra];
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
  NSArray * args = @[@"-c", @"/usr/bin/top -l 1 -stats pid,cpu,rsize"];
  
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
        [NSNumber numberWithDouble: cached]
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
  NSLog(@"top line: %@", line);
  NSLog(@"major OS version: %d", [[Model model] majorOSVersion]);
  if([[Model model] majorOSVersion] >= kMavericks)
    return [self formatTop9: line];
  
  return [self formatTop6: line];
  }

// Format output from top (OS X 10.6 or later) into something useable.
- (NSDictionary *) formatTop6: (NSString *) line
  {
  NSScanner * scanner = [NSScanner scannerWithString: line];
  
  [scanner scanString: @"PhysMem:" intoString: NULL];
  
  double wired = [Utilities scanTopMemory: scanner];

  [scanner scanString: @"wired," intoString: NULL];

  [Utilities scanTopMemory: scanner];
  
  [scanner scanString: @"active," intoString: NULL];

  [Utilities scanTopMemory: scanner];
  
  [scanner scanString: @"inactive," intoString: NULL];

  double used = [Utilities scanTopMemory: scanner];
  
  [scanner scanString: @"used," intoString: NULL];

  double free = [Utilities scanTopMemory: scanner];
  
  [scanner scanString: @"free." intoString: NULL];

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

// Format output from top (OS X 10.9 or later) into something useable.
- (NSDictionary *) formatTop9: (NSString *) line
  {
  NSScanner * scanner = [NSScanner scannerWithString: line];
  
  [scanner scanString: @"PhysMem:" intoString: NULL];
  
  double used = [Utilities scanTopMemory: scanner];
  
  [scanner scanString: @"used (" intoString: NULL];

  double wired = [Utilities scanTopMemory: scanner];

  [scanner scanString: @"wired)," intoString: NULL];

  double free = [Utilities scanTopMemory: scanner];
  
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

  double used = [Utilities scanTopMemory: scanner];
  
  return
    @{
      NSLocalizedString(@"Swap Used", NULL) :
        [NSNumber numberWithDouble: used]
    };
  }

@end
