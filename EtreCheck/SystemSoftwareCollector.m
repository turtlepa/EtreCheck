/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "SystemSoftwareCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "TTTLocalizedPluralString.h"
#import "NSArray+Etresoft.h"

// Collect system software information.
@implementation SystemSoftwareCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"systemsoftware";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
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
    NSArray * plist = [NSArray readPropertyListData: result];
  
    if(plist && [plist count])
      {
      NSArray * items =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([items count])
        {
        [self.result appendAttributedString: [self buildTitle]];
        
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
  int hours = 0;

  BOOL parsed = [self parseUpTime: uptime days: & days hours: & hours];
  
  if(!parsed)
    return
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              NSLocalizedString(@"    %@ - Uptime: %@%@\n", NULL),
              version,
              @"",
              uptime]];
    
  NSString * dayString = TTTLocalizedPluralString(days, @"day", nil);
  NSString * hourString = TTTLocalizedPluralString(hours, @"hour", nil);
  
  if(days > 0)
    hourString = @"";
    
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(@"    %@ - Uptime: %@%@\n", NULL),
          version,
          dayString,
          hourString]];
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
    
    bool found = [scanner scanInt: & majorVersion];
    
    if(found)
      [[Model model]
        setMajorOSVersion: majorVersion];
    }
  }

// Parse system uptime.
- (bool) parseUpTime: (NSString *) uptime
  days: (int *) days hours: (int *) hours
  {
  NSScanner * scanner = [NSScanner scannerWithString: uptime];

  bool found = [scanner scanString: @"up " intoString: NULL];

  if(!found)
    return found;

  found = [scanner scanInt: days];

  if(!found)
    return found;

  found = [scanner scanString: @":" intoString: NULL];

  if(!found)
    return found;

  found = [scanner scanInt: hours];
  
  if(*hours >= 18)
    ++*days;
    
  return found;
  }

@end
