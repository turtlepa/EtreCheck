/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import "AdwareManager.h"
#import "Model.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"

#define kMinWidth 600
#define kMaxWidth 1000
#define kMinHeight 300
#define kMaxHeight 1000

@implementation AdwareManager

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
  
  [self resizeDetail];
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
  if(self.popoverViewController)
    {
    NSTextStorage * storage =
      [[NSTextStorage alloc] initWithAttributedString: self.details];
      
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
  
// Go to Adware Medic.
- (IBAction) gotoAdwareMedic: (id) sender
  {
  [[NSWorkspace sharedWorkspace]
    openURL: [NSURL URLWithString: @"http://www.adwaremedic.com"]];
  }

@end
