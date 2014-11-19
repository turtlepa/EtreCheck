/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "DiagnosticsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "TTTLocalizedPluralString.h"
#import "DiagnosticEvent.h"
#import "NSArray+Etresoft.h"

// Collect diagnostics information.
@implementation DiagnosticsCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"diagnostics";
    self.progressEstimate = 1;
    
    events = [NSMutableDictionary new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [events release];
  
  [super dealloc];
  }

// Perform the collection.
- (void) collect
  {
  // TODO: Localize this.
  [self
    updateStatus:
      NSLocalizedString(@"Checking diagnostics information", NULL)];

  [self collectDiagnostics];
  [self collectCrashReporter];
  [self collectDiagnosticReports];
  [self collectUserDiagnosticReports];
  [self collectCPU];
  
  if([events count] || insufficientPermissions)
    {
    // TODO: Localize this.
    [self.result
      appendAttributedString:
        [self buildTitle: @"Diagnostics Information:"]];
      
    [self printDiagnostics];
    
    // TODO: Localize this.
    if(insufficientPermissions)
      [self.result
        appendString:
          NSLocalizedString(
            @"/Library/Logs/DiagnosticReports permissions", NULL)];
    
    [self.result appendCR];
    }
  
  dispatch_semaphore_signal(self.complete);
  }

// Collect diagnostics.
- (void) collectDiagnostics
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPDiagnosticsDataType"
    ];
  
  NSData * result =
    [Utilities execute: @"/usr/sbin/system_profiler" arguments: args];
  
  if(!result)
    return;
    
  NSArray * plist = [NSArray readPropertyListData: result];

  if(![plist count])
    return;
    
  NSArray * results =
    [[plist objectAtIndex: 0] objectForKey: @"_items"];
    
  if(![results count])
    return;

  for(NSDictionary * result in results)
    [self collectDiagnosticResult: result];
  }

// Collect a single diagnostic result.
- (void) collectDiagnosticResult: (NSDictionary *) result
  {
  NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
   
  [dateFormatter setDateFormat: @"yyyy-MM-dd"];
  [dateFormatter setLocale: [NSLocale currentLocale]];

  NSString * name = [result objectForKey: @"_name"];
  
  if([name isEqualToString: @"spdiags_post_value"])
    {
    NSDate * lastRun =
      [result objectForKey: @"spdiags_last_run_key"];
    
    NSString * testResult =
      [result objectForKey: @"spdiags_result_key"];
    
    // TODO: Localize this.
    DiagnosticEvent * event =
      [self
        findEvent: NSLocalizedString(@"Self test", NULL)
        on: [dateFormatter stringFromDate: lastRun]];
    
    if(![event.testResult isEqualToString: testResult])
      event.testResult =
        [event.testResult stringByAppendingFormat: @", %@", testResult];
      
    if([testResult isEqualToString: @"spdiags_passed_value"])
      event.passingCount = event.passingCount + 1;
    else
      event.failureCount = event.failureCount + 1;
    }
  }

// Collect files in /Library/Logs/CrashReporter.
- (void) collectCrashReporter
  {
  NSArray * args =
    @[
      @"/Library/Logs/CrashReporter",
      @"-iname",
      @"*.gz"];
  
  NSData * data = [Utilities execute: @"/usr/bin/find" arguments: args];
  
  NSArray * files = [Utilities formatLines: data];
  
  for(NSString * file in files)
    {
    NSArray * parts =
      [[file lastPathComponent] componentsSeparatedByString: @".log."];
    
    if([parts count] > 1)
      {
      NSString * name = [parts firstObject];
      NSString * date = nil;
      NSString * fullDate = [parts objectAtIndex: 1];
      
      if([fullDate length] > 7)
        date =
          [NSString
            stringWithFormat:
              @"%@-%@-%@",
              [fullDate substringWithRange: NSMakeRange(0, 4)],
              [fullDate substringWithRange: NSMakeRange(4, 2)],
              [fullDate substringWithRange: NSMakeRange(6, 2)]];
      
      if(name && date)
        {
        DiagnosticEvent * event = [self findEvent: name on: date];
        
        event.crashCount = event.crashCount + 1;
        }
      }
    }
  }

// Collect files in /Library/Logs/DiagnosticReports.
- (void) collectDiagnosticReports
  {
  NSArray * args =
    @[
      @"/Library/Logs/DiagnosticReports",
      @"-iname",
      @"*.crash"
    ];
  
  NSData * data = [Utilities execute: @"/usr/bin/find" arguments: args];
  
  NSArray * files = [Utilities formatLines: data];
  
  NSString * permissionsError =
    @"find: /Library/Logs/DiagnosticReports: Permission denied";

  if([[files firstObject] isEqualToString: permissionsError])
    insufficientPermissions = YES;
  else
    [self parseDiagnosticReports: files];
  }

// Collect files in ~/Library/Logs/DiagnosticReports.
- (void) collectUserDiagnosticReports
  {
  NSString * diagnosticReportsDir =
    [NSHomeDirectory()
      stringByAppendingPathComponent: @"Library/Logs/DiagnosticReports"];

  NSArray * args =
    @[
      diagnosticReportsDir,
      @"-iname",
      @"*.crash"
    ];
  
  NSData * data = [Utilities execute: @"/usr/bin/find" arguments: args];
  
  [self parseDiagnosticReports: [Utilities formatLines: data]];
  }

// Parse diagnostic reports.
- (void) parseDiagnosticReports: (NSArray *) files
  {
  for(NSString * file in files)
    {
    NSArray * parts =
      [[file lastPathComponent] componentsSeparatedByString: @"_"];
    
    if([parts count] > 1)
      {
      NSString * name = [parts firstObject];
      NSString * date = nil;
      NSString * fullDate = [parts objectAtIndex: 1];

      if([fullDate length] > 7)
        date = [fullDate substringToIndex: 10];
      
      if(name && date)
        {
        DiagnosticEvent * event = [self findEvent: name on: date];
        
        event.crashCount = event.crashCount + 1;
        }
      }
    }
  }

// Collect CPU usage reports.
- (void) collectCPU
  {
  NSArray * args =
    @[
      @"/Library/Logs/DiagnosticReports",
      @"-iname",
      @"*.cpu_resource.diag"];
  
  NSData * data = [Utilities execute: @"/usr/bin/find" arguments: args];
  
  NSArray * files = [Utilities formatLines: data];
  
  for(NSString * file in files)
    {
    NSArray * parts =
      [[file lastPathComponent] componentsSeparatedByString: @"_"];
    
    if([parts count] > 1)
      {
      NSString * name = [self cpuHogName: file];
      NSString * date = nil;
      NSString * fullDate = [parts objectAtIndex: 1];

      if([fullDate length] > 7)
        date = [fullDate substringToIndex: 10];
      
      if(name && date)
        {
        DiagnosticEvent * event = [self findEvent: name on: date];
        
        event.cpuCount = event.cpuCount + 1;
        }
      }
    }
  }

// Get the name of a CPU hog.
- (NSString *) cpuHogName: (NSString *) path
  {
  NSString * name = nil;
  
  NSData * data = [NSData dataWithContentsOfFile: path];
  
  NSArray * lines = [Utilities formatLines: data];
  
  for(NSString * line in lines)
    if([line hasPrefix: @"Path:            "])
      name = [[line substringFromIndex: 17] lastPathComponent];

  if([name isEqualToString: @"???"])
    for(NSUInteger i = 0; i < [lines count]; ++i)
      {
      NSString * line = [lines objectAtIndex: i];
      
      if([line hasPrefix: @"  Binary Images:"])
        if((i + 2) < [lines count])
          {
          NSArray * parts =
            [[lines objectAtIndex: i + 2] componentsSeparatedByString:@"/"];
            
          name = [parts lastObject];
          }
      }

  return name;
  }

// Print crash logs.
- (void) printDiagnostics
  {
  NSArray * dates =
    [[events allKeys]
      sortedArrayUsingComparator:
        ^NSComparisonResult(id obj1, id obj2)
          {
          return -1 * [obj1 compare: obj2];
          }];
    
  NSUInteger i = 0;
  
  for(NSString * date in dates)
    {
    [self.result
      appendString:
        [NSString stringWithFormat: @"\t%@:\n", date]];
      
    NSDictionary * dayEvents = [events objectForKey: date];
    
    for(NSString * name in dayEvents)
      {
      BOOL problem = NO;
      
      NSString * status =
        [self
          collectDiagnosticStatusFor: name
          inEvents: dayEvents
          problem: & problem];
      
      // TODO: Make red on failure.
      [self.result
        appendString:
          [NSString stringWithFormat: @"\t\t%@ (%@)\n", name, status]];
      }
      
    ++i;
    
    if(i >= 3)
      break;
    }
  }

// Collect diagnostic status for a single day event.
- (NSString *) collectDiagnosticStatusFor: (NSString *) name
  inEvents: (NSDictionary *) dayEvents
  problem: (BOOL *) problem
  {
  DiagnosticEvent * event = [dayEvents objectForKey: name];
  
  NSMutableArray * items = [NSMutableArray array];
  
  // TODO: Localize this.
  if(event.crashCount)
    [items
      addObject:
        TTTLocalizedPluralString(event.crashCount, @"crash", NULL)];
    
  // TODO: Localize this.
  if(event.cpuCount)
    [items
      addObject:
        TTTLocalizedPluralString(event.cpuCount, @"overload", NULL)];
    
  // TODO: Localize this.
  if(event.passingCount)
    [items
      addObject:
        [NSString
          stringWithFormat:
            NSLocalizedString(@"Passing: %d", NULL), event.passingCount]];

  // TODO: Localize this.
  if(event.failureCount)
    {
    if(problem)
      *problem = YES;
      
    [items
      addObject:
        [NSString
          stringWithFormat:
            NSLocalizedString(@"Failing: %d", NULL), event.failureCount]];
    }

  return [items componentsJoinedByString: @" - "];
  }
  
// Get an existing event or create a new one.
- (DiagnosticEvent *) findEvent: (NSString *) name on: (NSString *) date
  {
  NSMutableDictionary * dayEvents = [events objectForKey: date];
  
  if(!dayEvents)
    {
    dayEvents = [NSMutableDictionary new];
    
    [events setObject: dayEvents forKey: date];
    
    [dayEvents release];
    }
    
  DiagnosticEvent * event = [dayEvents objectForKey: name];
  
  if(!event)
    {
    event = [DiagnosticEvent new];
    
    [dayEvents setObject: event forKey: name];
    
    [event release];
    
    event.date = date;
    event.name = name;
    }
    
  return event;
  }

@end
