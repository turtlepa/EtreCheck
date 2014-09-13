/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "PreferencePanesCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"

// Collect 3rd party preference panes.
@implementation PreferencePanesCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    self.name = @"preferencepanes";
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Checking preference panes", NULL)];

  NSArray * args =
    @[
      @"-xml",
      @"SPPrefPaneDataType"
    ];
  
  NSData * result =
    [Utilities execute: @"/usr/sbin/system_profiler" arguments: args];
  
  if(result)
    {
    NSArray * plist = [Utilities readPropertyListData: result];
  
    if(plist && [plist count])
      {
      NSArray * items =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([items count])
        {
        [self.result
          appendAttributedString:
            [self buildTitle: @"3rd Party Preference Panes:"]];
        
        NSUInteger count = 0;
        
        for(NSDictionary * item in items)
          if([self printPreferencePaneInformation: item])
            ++count;
          
        if(!count)
          [self.result appendString: NSLocalizedString(@"\tNone\n", NULL)];
          
        [self.result appendCR];
        }
      }
    }
  }

// Print information for a preference pane.
// Return YES if this is a 3rd party preference pane.
- (BOOL) printPreferencePaneInformation: (NSDictionary *) item
  {
  NSString * name = [item objectForKey: @"_name"];
  NSString * support = [item objectForKey: @"spprefpane_support"];
  NSString * bundleID =
    [item objectForKey: @"spprefpane_identifier"];

  if([support isEqualToString: @"spprefpane_support_3rdParty"])
    {
    [self.result
      appendString: [NSString stringWithFormat: @"\t%@ ", name]];
      
    NSAttributedString * supportLink =
      [self getSupportURL: name bundleID: bundleID];
      
    if(supportLink)
      [self.result appendAttributedString: supportLink];
      
    [self.result appendString: @"\n"];
    
    return YES;
    }
    
  return NO;
  }

@end
