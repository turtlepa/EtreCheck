/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface AdwareManager : NSObject
  {
  NSView * myContentView;
  
  // My detail drawer.
  NSDrawer * myDrawer;
  
  // My popover view controller.
  NSViewController * myPopoverViewController;
  
  // My detail drawer/popover.
  id myDetail;
  
  // My detail label.
  NSTextField * myTitle;
  
  // My text content.
  NSTextView * myTextView;
  
  // The current details text.
  NSAttributedString * myDetails;
  }
  
@property (retain) IBOutlet NSView * contentView;
@property (retain) IBOutlet NSDrawer * drawer;
@property (retain) IBOutlet NSViewController * popoverViewController;
@property (retain) IBOutlet id detail;
@property (retain) IBOutlet NSTextField * title;
@property (retain) IBOutlet NSTextView * textView;
@property (retain) NSAttributedString * details;

// Show detail.
- (void) showDetail: (NSString *) content;

// Close the detail.
- (IBAction) closeDetail: (id) sender;

// Go to Adware Medic.
- (IBAction) gotoAdwareMedic: (id) sender;

@end
