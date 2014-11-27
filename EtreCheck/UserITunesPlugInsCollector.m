/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "UserITunesPlugInsCollector.h"

// Collect user iTunes plug-ins.
@implementation UserITunesPlugInsCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"useritunesplugins";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking user iTunes plug-ins", NULL)];

  [self
    parseUserPlugins: NSLocalizedString(@"User iTunes Plug-ins:", NULL)
    path:  @"/Library/iTunes/iTunes Plug-ins"];
    
  dispatch_semaphore_signal(self.complete);
  }

@end
