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

    self.progressEstimate = 10;
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking virtual memory information", NULL)];

  NSDictionary * vminfo = [self collectVirtualMemoryInformation];
    
  [self.result appendAttributedString: [self buildTitle]];

  formatter = [[ByteCountFormatter alloc] init];

  [self printVM: vminfo forKey: NSLocalizedString(@"Free RAM", NULL)];
  [self printVM: vminfo forKey: NSLocalizedString(@"Active RAM", NULL)];
  [self printVM: vminfo forKey: NSLocalizedString(@"Inactive RAM", NULL)];
  [self printVM: vminfo forKey: NSLocalizedString(@"Wired RAM", NULL)];
  [self printVM: vminfo forKey: NSLocalizedString(@"Page-ins", NULL)];
  
  NSUInteger GB = 1024 * 1024 * 1024;

  if(pageouts > (GB * 1))
    [self
      printVM: vminfo
      forKey: NSLocalizedString(@"Page-outs", NULL)
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red]
        }];
  else
    [self printVM: vminfo forKey: NSLocalizedString(@"Page-outs", NULL)];

  [self
    setTabs: @[@28, @112, @196]
    forRange: NSMakeRange(0, [self.result length])];

  [self.result appendCR];

  [formatter release];
    
  dispatch_semaphore_signal(self.complete);
  }

// Collect virtual memory information.
- (NSDictionary *) collectVirtualMemoryInformation
  {
  NSMutableDictionary * vminfo = [NSMutableDictionary dictionary];
  
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
    
  return vminfo;
  }

// Format output from vm_stats into something useable.
- (NSDictionary *) formatVMStats: (NSDictionary *) vm_stats
  {
  NSString * statisticsValue =
    [vm_stats objectForKey: @"Mach Virtual Memory Statistics"];
  NSString * freeValue = [vm_stats objectForKey: @"Pages free"];
  NSString * activeValue = [vm_stats objectForKey: @"Pages active"];
  NSString * inactiveValue = [vm_stats objectForKey: @"Pages inactive"];
  NSString * speculativeValue =
    [vm_stats objectForKey: @"Pages speculative"];
  NSString * wiredValue = [vm_stats objectForKey: @"Pages wired down"];
  NSString * pageinsValue = [vm_stats objectForKey: @"Pageins"];
  NSString * pageoutsValue = [vm_stats objectForKey: @"Pageouts"];

  double pageSize = [self parsePageSize: statisticsValue];
  
  double free = [freeValue doubleValue] * pageSize;
  double active = [activeValue doubleValue]  * pageSize;
  double inactive = [inactiveValue doubleValue] * pageSize;
  double speculative = [speculativeValue doubleValue] * pageSize;
  double wired = [wiredValue doubleValue] * pageSize;
  double pageins = [pageinsValue doubleValue] * pageSize;
  pageouts = [pageoutsValue doubleValue] * pageSize;

  free += speculative;
  
  return
    @{
      NSLocalizedString(@"Free RAM", NULL) :
        [NSNumber numberWithDouble: free],
      NSLocalizedString(@"Active RAM", NULL) :
        [NSNumber numberWithDouble: active],
      NSLocalizedString(@"Inactive RAM", NULL) :
        [NSNumber numberWithDouble: inactive],
      NSLocalizedString(@"Wired RAM", NULL) :
        [NSNumber numberWithDouble: wired],
      NSLocalizedString(@"Page-ins", NULL) :
        [NSNumber numberWithDouble: pageins],
      NSLocalizedString(@"Page-outs", NULL) :
        [NSNumber numberWithDouble: pageouts]
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

// Print a VM value.
- (void) printVM: (NSDictionary *) vminfo forKey: (NSString *) key
  {
  double value = [[vminfo objectForKey: key] doubleValue];
  
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          @"\t%-9@\t%@\n", [formatter stringFromByteCount: value], key]];
  }

// Print a VM value.
- (void) printVM: (NSDictionary *) vminfo
  forKey: (NSString *) key attributes: (NSDictionary *) attributes
  {
  double value = [[vminfo objectForKey: key] doubleValue];
  
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          @"\t%-9@\t%@\n", [formatter stringFromByteCount: value], key]
    attributes: attributes];
  }

@end
