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
    self.name = @"itunesplugins";
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Checking iTunes plug-ins", NULL)];

  [self
    parsePlugins: NSLocalizedString(@"iTunes Plug-ins:", NULL)
    path:  @"/Library/iTunes/iTunes Plug-ins"];
  }

@end
