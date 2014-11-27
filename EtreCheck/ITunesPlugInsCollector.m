/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "ITunesPlugInsCollector.h"

// Collect iTunes plug-ins.
@implementation ITunesPlugInsCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"itunesplugins";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Checking iTunes plug-ins", NULL)];

  [self parsePlugins: @"/Library/iTunes/iTunes Plug-ins"];
    
  dispatch_semaphore_signal(self.complete);
  }

@end
