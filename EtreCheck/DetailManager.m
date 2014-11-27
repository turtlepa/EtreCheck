/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import "DetailManager.h"
#import "Model.h"
#import "DiagnosticEvent.h"

#define kMinWidth 600
#define kMaxWidth 1000
#define kMinHeight 300
#define kMaxHeight 1000

@implementation DetailManager

@synthesize contentView = myContentView;
@synthesize drawer = myDrawer;
@synthesize popoverViewController = myPopoverViewController;
@synthesize detail = myDetail;
@synthesize title = myTitle;
@synthesize textView = myTextView;
@synthesize details = myDetails;

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    myDetail = myDrawer;
    
    if([NSPopover class])
      {
      NSPopover * popover = [[NSPopover alloc] init];
      
      popover.delegate = (id<NSPopoverDelegate>)self;
      
      myDetail = popover;
      }
    else
      self.popoverViewController = nil;
    }
  
  return self;
  }

// Destructor.
- (void) dealloc
  {
  self.details = nil;
  
  if(self.popoverViewController)
    [myDetail release];
    
  [super dealloc];
  }

// Setup nib connections.
- (void) awakeFromNib
  {
  if(self.popoverViewController)
    {
    [self.detail setContentViewController: self.popoverViewController];
    [self.detail setContentSize: NSMakeSize(kMinWidth, kMinHeight)];
    [self.detail setBehavior: NSPopoverBehaviorApplicationDefined];
    }
  }

// Show detail.
- (void) showDetail: (NSString *) name
  {
  [self showDetailPane];
    
  [self.title
    setStringValue:
      [NSString
        stringWithFormat:
          NSLocalizedString(@"Details for %@", NULL), name]];
  
  DiagnosticEvent * event =
    [[[Model model] diagnosticEvents] objectForKey: name];
  
  NSString * details = event.details;
  
  if(![details length])
    details = NSLocalizedString(@"No details available", NULL);
    
  NSRange range = NSMakeRange(0, [[self.textView textStorage] length]);

  [self.textView replaceCharactersInRange: range withString: details];
  
  [self resizeDetail];
  }

// Close the detail.
- (IBAction) closeDetail: (id) sender
  {
  [self.detail close];
  }

// Show the detail pane.
- (void) showDetailPane
  {
  if(self.popoverViewController)
    {
    NSPoint clickPoint =
      [self.contentView
        convertPoint:
          [[self.contentView window] mouseLocationOutsideOfEventStream]
        fromView: nil];
    
    NSRect rect = NSMakeRect(clickPoint.x, clickPoint.y, 40, 1);
    
    [self.detail
      showRelativeToRect: rect
      ofView: self.contentView
      preferredEdge: NSMaxXEdge];
    }
  else
    {
    NSDrawerState currentState = [self.detail state];
    
    switch(currentState)
      {
      case NSDrawerClosedState:
        [self.detail setMinContentSize: NSMakeSize(kMinWidth, kMinHeight)];
        [self.detail setContentSize: NSMakeSize(kMinWidth, kMinHeight)];
        [self.detail openOnEdge: [self.drawer preferredEdge]];
        break;
        
      default:
        break;
      }
    }
  }

// Resize the detail pane to match the content.
- (void) resizeDetail
  {
  NSUInteger numberOfLines = 0;
  NSUInteger stringLength = [self.details length];
  
  for(NSUInteger index = 0; index < stringLength; ++numberOfLines)
    {
    NSUInteger nextIndex =
      NSMaxRange([self.details lineRangeForRange: NSMakeRange(index, 0)]);
      
    NSUInteger wraps = (nextIndex - index) / 80;
    
    numberOfLines += wraps;
    
    index = nextIndex;
    }
    
  double height =
    [[self.textView layoutManager]
      defaultLineHeightForFont: [self.textView font]];
    
  if(self.popoverViewController)
    {
    NSSize size = [self.detail contentSize];
    
    size.height = (height * (numberOfLines + 1)) + 80;
    
    if(size.height > kMaxHeight)
      size.height = kMaxHeight;
    else if(size.height < kMinHeight)
      size.height = kMinHeight;
    
    [self.detail setContentSize: size];
    [self.textView scrollRangeToVisible: NSMakeRange(0, 1)];
    }
  }
  
@end
