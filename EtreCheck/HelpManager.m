/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import "HelpManager.h"
#import "Model.h"
#import "DiagnosticEvent.h"

#define kMinWidth 400
#define kMaxWidth 1000
#define kMinHeight 76
#define kMaxHeight 1000

@implementation HelpManager

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
    
  // TODO: Localize this.
  [self.title
    setStringValue:
      [NSString
        stringWithFormat:
          NSLocalizedString(@"Help for %@", NULL),
          NSLocalizedStringFromTable(name, @"Collectors", NULL)]];
  
  NSString * details = NSLocalizedStringFromTable(name, @"Help", NULL);
  
  // TODO: Localize this.
  if(![details length])
    details = NSLocalizedString(@"No help available", NULL);
    
  self.details = details;
  
  [self resizeDetail];
  }

// Resize the detail pane to match the content.
- (void) resizeDetail
  {
  if(self.popoverViewController)
    {
    NSTextStorage * storage =
      [[NSTextStorage alloc] initWithString: self.details];
      
    NSSize size = [self.detail contentSize];

    size.width = kMinWidth - 36;
    size.height = FLT_MAX;
    
    NSTextContainer * container =
      [[NSTextContainer alloc] initWithContainerSize: size];
    NSLayoutManager * manager = [[NSLayoutManager alloc] init];
      
    [manager addTextContainer: container];
    [storage addLayoutManager: manager];
     
    [storage
      addAttribute: NSFontAttributeName
      value: [NSFont systemFontOfSize: 15]
      range: NSMakeRange(0, [storage length])];
      
    // Use the same old layout behaviour that the table view uses.
    //[manager
    //  setTypesetterBehavior: NSTypesetterBehavior_10_2_WithCompatibility];
    [manager glyphRangeForTextContainer: container];
    
    NSRect idealRect = [manager usedRectForTextContainer: container];
      
    [manager release];
    [container release];
    [storage release];
    
    size.height = idealRect.size.height + 76;
    
    [self.detail setContentSize: size];
    [self.textView scrollRangeToVisible: NSMakeRange(0, 1)];
    }
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
      preferredEdge: NSMinXEdge];
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

@end
