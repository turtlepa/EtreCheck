/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import "DetailManager.h"
#import "Model.h"
#import "DiagnosticEvent.h"

@implementation DetailManager

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
    
  [self.title setStringValue: name];
  
  DiagnosticEvent * event =
    [[[Model model] diagnosticEvents] objectForKey: name];
  
  NSString * details = event.details;
  
  if(![details length])
    details = NSLocalizedString(@"No details available", NULL);
    
  NSRange range = NSMakeRange(0, [[self.textView textStorage] length]);

  [self.textView replaceCharactersInRange: range withString: details];
  
  NSTextStorage * storage =
    [[NSTextStorage alloc] initWithString: self.details];

  [self resizeDetail: storage];
  
  [storage release];

  [self.textView scrollRangeToVisible: NSMakeRange(0, 1)];
  }
  
@end
