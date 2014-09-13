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
    self.name = @"audioplugins";
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Checking audio plug-ins", NULL)];

  [self
    parsePlugins: NSLocalizedString(@"Audio Plug-ins:", NULL)
    path:  @"/Library/Audio/Plug-ins"];
  }

@end
