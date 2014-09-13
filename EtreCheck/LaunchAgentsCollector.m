/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "LaunchAgentsCollector.h"
#import "Utilities.h"

@implementation LaunchAgentsCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.progressEstimate = 0.3;
    self.name = @"launchagents";
    }
    
  return self;
  }

// Collect 3rd party launch agents.
- (void) collect
  {
  [self updateStatus: NSLocalizedString(@"Checking launch agents", NULL)];

  // Make sure the base class is setup.
  [super collect];
  
  NSArray * args =
    @[
      @"/Library/LaunchAgents",
      @"-type", @"f",
      @"-or",
      @"-type", @"l"
    ];
  
  NSData * result = [Utilities execute: @"/usr/bin/find" arguments: args];
  
  NSArray * files = [Utilities formatLines: result];
  
  [self
    formatPropertyListFiles: files
    title: NSLocalizedString(@"Launch Agents:", NULL)];
  }
  
@end
