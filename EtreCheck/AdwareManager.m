/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import "AdwareManager.h"
#import "Model.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"

@interface PopoverManager ()

// Show detail.
- (void) showDetail: (NSString *) title
  content: (NSAttributedString *) content;

@end

@implementation AdwareManager

// Show detail.
- (void) showDetail: (NSString *) name
  {
  NSMutableAttributedString * details = [NSMutableAttributedString new];
  
  [details appendString: NSLocalizedString(@"adwaredetails1", NULL)];
  
  [details appendAttributedString: [self getAppleLink]];
  
  [details appendString: NSLocalizedString(@"adwaredetails2", NULL)];

  [[[Model model] adwareFiles]
    enumerateKeysAndObjectsUsingBlock:
      ^(id key, id obj, BOOL * stop)
        {
        if([name isEqualToString: obj])
          {
          [details appendString: [Utilities sanitizeFilename: key]];
          [details appendString: @"\n"];
          }
        }];
  
  [details appendString: NSLocalizedString(@"adwaredetails3", NULL)];

  [super
    showDetail: NSLocalizedString(@"About adware", NULL) content: details];
    
  [details release];
  }

// Get a link to the Apple support document about adware.
- (NSAttributedString *) getAppleLink
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  NSString * appleURL = @"http://support.apple.com/HT203987";
  
  [urlString
    appendString: appleURL
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] blue],
        NSLinkAttributeName : appleURL
      }];
    
  return [urlString autorelease];
  }

// Go to Adware Medic.
- (IBAction) gotoAdwareMedic: (id) sender
  {
  [[NSWorkspace sharedWorkspace]
    openURL: [NSURL URLWithString: @"http://www.adwaremedic.com"]];
  }

@end
