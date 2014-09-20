/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "UserInternetPlugInsCollector.h"

// Collect user internet plug-ins.
@implementation UserInternetPlugInsCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    self.name = @"userinternetplugins";
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking user internet plug-ins", NULL)];

  [self
    parseUserPlugins: NSLocalizedString(@"User Internet Plug-ins:", NULL)
    path: @"Library/Internet Plug-Ins"];
    
  dispatch_semaphore_signal(self.complete);
  }

@end
