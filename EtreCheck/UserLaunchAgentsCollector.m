/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "UserLaunchAgentsCollector.h"
#import "Utilities.h"

@implementation UserLaunchAgentsCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"userlaunchagents";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Collect user launch agents.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Checking user launch agents", NULL)];

  // Make sure the base class is setup.
  [super collect];
  
  NSString * launchAgentsDir =
    [NSHomeDirectory()
      stringByAppendingPathComponent: @"Library/LaunchAgents"];

  if([[NSFileManager defaultManager] fileExistsAtPath: launchAgentsDir])
    {
    NSArray * args =
      @[
        launchAgentsDir,
        @"-type", @"f",
        @"-or",
        @"-type", @"l"
      ];
    
    NSData * result = [Utilities execute: @"/usr/bin/find" arguments: args];
    
    NSArray * files = [Utilities formatLines: result];
    
    [self printPropertyListFiles: files];
    }
    
  dispatch_semaphore_signal(self.complete);
  }

@end
