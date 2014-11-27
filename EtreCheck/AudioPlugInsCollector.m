/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "AudioPlugInsCollector.h"

// Collect audio plug-ins.
@implementation AudioPlugInsCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"audioplugins";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Checking audio plug-ins", NULL)];

  [self parsePlugins: @"/Library/Audio/Plug-ins"];
    
  dispatch_semaphore_signal(self.complete);
  }

@end
