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
    self.name = @"internetplugins";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Checking internet plug-ins", NULL)];

  [self parsePlugins: @"/Library/Internet Plug-Ins"];
    
  dispatch_semaphore_signal(self.complete);
  }

@end
