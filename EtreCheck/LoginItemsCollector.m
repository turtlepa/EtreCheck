/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "LoginItemsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"

// Collect login items.
@implementation LoginItemsCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.progressEstimate = 1.6;
    self.name = @"loginitems";
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self updateStatus: NSLocalizedString(@"Checking login items", NULL)];

  [self.result
    appendAttributedString: [self buildTitle: @"User Login Items:"]];
    
  NSArray * args =
    @[
      @"-e",
      @"tell application \"System Events\" to get the name of every login item"
    ];
  
  NSData * result =
    [Utilities execute: @"/usr/bin/osascript" arguments: args];
  
  NSArray * paths = [Utilities formatLines: result];
  
  NSUInteger count = 0;
  
  for(NSString * path in paths)
    {
    NSString * file = [path lastPathComponent];
    
    if([file length])
      {
      [self.result
        appendString: [NSString stringWithFormat: @"\t%@\n", file]];
      
      ++count;
      }
    }
    
  if(!count)
    [self.result appendString: NSLocalizedString(@"\tNone\n", NULL)];
  
  [self.result appendCR];
  }

@end
