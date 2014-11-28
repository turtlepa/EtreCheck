/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "PopoverManager.h"

@interface DetailManager : PopoverManager
  {
  // My text content.
  NSTextView * myTextView;
  
  // The current details text.
  NSString * myDetails;
  }
  
@property (retain) IBOutlet NSTextView * textView;
@property (retain) NSString * details;

@end
