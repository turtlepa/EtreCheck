/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "InternetPlugInsCollector.h"

// Collect internet plug-ins.
@implementation InternetPlugInsCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.progressEstimate = 1.0;
    self.name = @"internetplugins";
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Checking internet plug-ins", NULL)];

  [self
    parsePlugins: NSLocalizedString(@"Internet Plug-ins:", NULL)
    path:  @"/Library/Internet Plug-Ins"];
  }

@end
