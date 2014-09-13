/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "SystemLaunchAgentsCollector.h"
#import "Utilities.h"

@implementation SystemLaunchAgentsCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.progressEstimate = 1.9;
    self.name = @"systemlaunchagents";
    }
    
  return self;
  }

// Collect system launch agents.
- (void) collect
  {
  [self updateStatus: NSLocalizedString(@"Checking launch agents", NULL)];
 
  // Make sure the base class is setup.
  [super collect];
  
  NSArray * args =
    @[
      @"/System/Library/LaunchAgents",
      @"-type", @"f",
      @"-or",
      @"-type", @"l"
    ];
  
  NSData * result = [Utilities execute: @"/usr/bin/find" arguments: args];
  
  NSArray * files = [Utilities formatLines: result];
  
  [self
    formatPropertyListFiles: files
    title: NSLocalizedString(@"Problem System Launch Agents:", NULL)];
  }
  
@end
