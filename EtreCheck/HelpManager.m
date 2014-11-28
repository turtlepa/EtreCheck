/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import "HelpManager.h"
#import "Model.h"
#import "DiagnosticEvent.h"

@implementation HelpManager

@synthesize textView = myTextView;
@synthesize details = myDetails;

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    myMinDrawerSize = NSMakeSize(300, 200);
    }
  
  return self;
  }

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
    
  [self.title
    setStringValue: NSLocalizedStringFromTable(name, @"Collectors", NULL)];
  
  NSString * details = NSLocalizedStringFromTable(name, @"Help", NULL);
  
  if(![details length])
    details = NSLocalizedString(@"No help available", NULL);
    
  self.details = details;
  
  NSTextStorage * storage =
    [[NSTextStorage alloc] initWithString: self.details];

  [self resizeDetail: storage];
  
  [storage release];

  [self.textView scrollRangeToVisible: NSMakeRange(0, 1)];
  }

@end
