/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "SystemLaunchDaemonsCollector.h"
#import "Utilities.h"

@implementation SystemLaunchDaemonsCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"systemlaunchdaemons";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Collect system launch daemons.
- (void) collect
  {
  [self updateStatus: NSLocalizedString(@"Checking launch daemons", NULL)];

  // Make sure the base class is setup.
  [super collect];
  
  NSArray * args =
    @[
      @"/System/Library/LaunchDaemons",
      @"-type", @"f",
      @"-or",
      @"-type", @"l"
    ];
  
  NSData * result = [Utilities execute: @"/usr/bin/find" arguments: args];
  
  NSArray * files = [Utilities formatLines: result];
  
  [self printPropertyListFiles: files];
    
  dispatch_semaphore_signal(self.complete);
  }
  
@end

