/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import "AdwareManager.h"
#import "Model.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"

@implementation AdwareManager

@synthesize textView = myTextView;
@synthesize details = myDetails;

// Destructor.
- (void) dealloc
  {
  self.details = nil;
  
  [super dealloc];
  }

// Show detail.
- (void) showDetail: (NSString *) name
  {
  [super showDetail: name];
    
  NSString * title =
    [NSString
      stringWithFormat: NSLocalizedString(@"About %@ adware", NULL), name];
    
  [self.title setStringValue: NSLocalizedString(title, NULL)];
  
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

  self.details = [details copy];
  
  [details release];
  
  NSData * rtfData =
    [self.details
      RTFFromRange: NSMakeRange(0, [self.details length])
      documentAttributes: nil];

  NSRange range = NSMakeRange(0, [[self.textView textStorage] length]);

  [self.textView replaceCharactersInRange: range withRTF: rtfData];
  
  NSTextStorage * storage =
    [[NSTextStorage alloc] initWithAttributedString: self.details];

  [self resizeDetail: storage];
  
  [storage release];
  }

// Get a link to the Apple support document about adware.
- (NSAttributedString *) getAppleLink
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  NSString * appleURL = @"http://support.apple.com/HT6506";
  
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
