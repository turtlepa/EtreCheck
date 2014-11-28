/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "PopoverManager.h"

@interface AdwareManager : PopoverManager
  {
  // My text content.
  NSTextView * myTextView;
  
  // The current details text.
  NSAttributedString * myDetails;
  }
  
@property (retain) IBOutlet NSTextView * textView;
@property (retain) NSAttributedString * details;

// Go to Adware Medic.
- (IBAction) gotoAdwareMedic: (id) sender;

@end
