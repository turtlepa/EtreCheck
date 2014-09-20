/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "SystemSoftwareCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "SystemInformation.h"
#import "Utilities.h"
#import "TTTLocalizedPluralString.h"

// Collect system software information.
@implementation SystemSoftwareCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.progressEstimate = 0.5;
    self.name = @"systemsoftware";
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self updateStatus: NSLocalizedString(@"Checking system software", NULL)];
    
  NSArray * args =
    @[
      @"-xml",
      @"SPSoftwareDataType"
    ];
  
  NSData * result =
    [Utilities execute: @"/usr/sbin/system_profiler" arguments: args];
  
  if(result)
    {
    NSArray * plist = [Utilities readPropertyListData: result];
  
    if(plist && [plist count])
      {
      NSArray * items =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([items count])
        {
        [self.result
          appendAttributedString: [self buildTitle: @"System Software:"]];
        
        for(NSDictionary * item in items)
          [self printSystemSoftware: item];

        [self.result appendCR];
        }
      }
    }
    
  dispatch_semaphore_signal(self.complete);
  }

// Print a system software item.
- (void) printSystemSoftware: (NSDictionary *) item
  {
  NSString * version = [item objectForKey: @"os_version"];
  NSString * uptime = [item objectForKey: @"uptime"];

  [self parseOSVersion: version];
  
  int days = 0;
  NSString * time = nil;

  if([self parseUpTime: uptime days: & days time: & time])
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            NSLocalizedString(@"\t%@ - Uptime: %@%@\n", NULL),
            version,
            TTTLocalizedPluralString(days, @"day", nil),
            time]];
  else
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            NSLocalizedString(@"\t%@ - Uptime: %@%@\n", NULL),
            version,
            @"",
            uptime]];
  }

// Parse the OS version.
- (void) parseOSVersion: (NSString *) profilerVersion
  {
  if(profilerVersion)
    {
    NSScanner * scanner = [NSScanner scannerWithString: profilerVersion];
    
    [scanner scanUpToString: @"(" intoString: NULL];
    [scanner scanString: @"(" intoString: NULL];
    
    int majorVersion = 0;
    
    BOOL found = [scanner scanInt: & majorVersion];
    
    if(found)
      [[SystemInformation sharedInformation]
        setMajorOSVersion: majorVersion];
    }
  }

// Parse system uptime.
- (BOOL) parseUpTime: (NSString *) uptime
  days: (int *) days time: (NSString **) time
  {
  NSScanner * scanner = [NSScanner scannerWithString: uptime];

  BOOL found = [scanner scanString: @"up " intoString: NULL];

  if(!found)
    return found;

  found = [scanner scanInt: days];

  if(!found)
    return found;

  found = [scanner scanString: @":" intoString: NULL];

  if(!found)
    return found;

  return [scanner scanUpToString: @"\n" intoString: time];
  }

@end
