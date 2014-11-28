/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import "PopoverManager.h"

@implementation PopoverManager

@synthesize minDrawerSize = myMinDrawerSize;
@synthesize maxDrawerSize = myMaxDrawerSize;
@synthesize minPopoverSize = myMinPopoverSize;
@synthesize maxPopoverSize = myMaxPopoverSize;
@synthesize contentView = myContentView;
@synthesize drawer = myDrawer;
@synthesize popoverViewController = myPopoverViewController;
@synthesize title = myTitle;
@synthesize popover = myPopover;

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    myMinDrawerSize = NSMakeSize(400, 200);
    myMaxDrawerSize = NSMakeSize(400, 1000);
    myMinPopoverSize = NSMakeSize(400, 200);
    myMaxPopoverSize = NSMakeSize(1000, 1000);
    
    if([NSPopover class])
      {
      NSPopover * popover = [[NSPopover alloc] init];
      
      popover.delegate = (id<NSPopoverDelegate>)self;
      
      myPopover = popover;
      }
    else
      myPopoverViewController = nil;
    }
  
  return self;
  }

// Destructor.
- (void) dealloc
  {
  if(self.popover)
    self.popover = nil;
    
  [super dealloc];
  }

// Setup nib connections.
- (void) awakeFromNib
  {
  if(self.popover)
    {
    [self.popover setContentViewController: self.popoverViewController];
    [self.popover setContentSize: self.minPopoverSize];
    [self.popover setBehavior: NSPopoverBehaviorApplicationDefined];
    }
  }

// Show detail.
- (void) showDetail: (NSString *) name
  {
  if(self.popover)
    {
    NSPoint clickPoint =
      [self.contentView
        convertPoint:
          [[self.contentView window] mouseLocationOutsideOfEventStream]
        fromView: nil];
    
    NSRect rect = NSMakeRect(clickPoint.x, clickPoint.y, 40, 1);
    
    [self.popover
      showRelativeToRect: rect
      ofView: self.contentView
      preferredEdge: NSMinXEdge];
    }
  else
    {
    NSDrawerState currentState = [self.drawer state];
    
    switch(currentState)
      {
      case NSDrawerClosedState:
        [self.drawer setMinContentSize: self.minDrawerSize];
        [self.drawer setContentSize: self.minDrawerSize];
        [self.drawer openOnEdge: [self.drawer preferredEdge]];
        break;
        
      default:
        break;
      }
    }
  }

// Resize the detail pane to match the content.
- (void) resizeDetail: (NSTextStorage *) storage
  {
  NSSize minWidth = self.minDrawerSize;
  
  if(self.popover)
    minWidth = self.minPopoverSize;
    
  NSSize size = [self.popover contentSize];

  size.width = minWidth.width - 36;
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
  
  size.width += 36;
  size.height = idealRect.size.height + 76;
    
  if(self.popover)
    [self.popover setContentSize: size];
  else
    [self.drawer setContentSize: size];
  }

// Close the detail.
- (IBAction) closeDetail: (id) sender
  {
  if(self.popover)
    [self.popover close];
  else
    [self.drawer close];
  }

@end
