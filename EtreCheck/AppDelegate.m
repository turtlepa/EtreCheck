/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import "AppDelegate.h"
#import "NSMutableAttributedString+Etresoft.h"
#import <ServiceManagement/ServiceManagement.h>
#import <unistd.h>
#import <CarbonCore/BackupCore.h>
#import "ByteCountFormatter.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "Utilities.h"
#import "Checker.h"
#import "SlideshowView.h"
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CoreImage.h>
#import "LaunchdCollector.h"
#import "SystemInformation.h"
#import "NSAttributedString+Etresoft.h"

@interface AppDelegate ()

- (void) collectInfo;

@end

@implementation AppDelegate

@synthesize window;
@synthesize logWindow = myLogWindow;
@synthesize progress = myProgress;
@synthesize spinner = mySpinner;
@synthesize statusView = myStatusView;
@synthesize logView;
@synthesize toClipboard;
@synthesize moreInfo;
@synthesize displayStatus = myDisplayStatus;
@synthesize log;
@synthesize currentProgressIncrement = myCurrentProgressIncrement;
@synthesize machineIcon = myMachineIcon;
@synthesize applicationIcon = myApplicationIcon;
@synthesize magnifyingGlass = myMagnifyingGlass;
@synthesize finderIcon = myFinderIcon;
@synthesize demonImage = myDemonImage;
@synthesize agentImage = myAgentImage;
@synthesize collectionStatus = myCollectionStatus;
@synthesize reportView = myReportView;
@synthesize animationView = myAnimationView;
@synthesize userMessage = myUserMessage;
@synthesize userMessgePanel = myUserMessagePanel;

// Destructor.
- (void) dealloc
  {
  self.displayStatus = nil;
  
  [super dealloc];
  }

// Start the application.
- (void) applicationDidFinishLaunching: (NSNotification *) aNotification
  {
  [self checkForUpdates];
  
  myDisplayStatus = [NSAttributedString new];
  self.log = [[NSMutableAttributedString new] autorelease];

  [self.logView
    setLinkTextAttributes:
      @{
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone),
        NSCursorAttributeName : [NSCursor pointingHandCursor]
      }];
    
  [self.machineIcon updateSubviewsWithTransition: kCATransitionFade];
  [self.machineIcon
    transitionToImage: [[Utilities shared] unknownMachineIcon]];

  [self.applicationIcon updateSubviewsWithTransition: kCATransitionPush];
  [self.applicationIcon
    transitionToImage: [[Utilities shared] genericApplicationIcon]];
    
  // Snow Leopard doesn't order views in a predictable fashion. New subviews
  // get added on top of all siblings, regardless of the relative order of
  // those siblings.
  self.applicationIcon.maskView = self.magnifyingGlass;
    
  [self.magnifyingGlass setHidden: NO];
    
  [self.finderIcon setImage: [[Utilities shared] FinderIcon]];
  [self.demonImage setHidden: NO];
  [self.agentImage setHidden: NO];
  
  [self.logView setHidden: YES];
  
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)),
    dispatch_get_main_queue(),
    ^{
      [self collectUserMessage];
    });
  }

// Check for a new version.
- (void) checkForUpdates
  {
  NSURL * url =
    [NSURL
      URLWithString:
        @"http://etresoft.com/download/ApplicationUpdates.plist"];
  
  NSData * data = [NSData dataWithContentsOfURL: url];
  
  if(data)
    {
    NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
      
    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
    
    NSString * appBundleId = [[NSBundle mainBundle] bundleIdentifier];
    
    NSNumber * appVersion =
      [numberFormatter
        numberFromString:
          [[[NSBundle mainBundle] infoDictionary]
            objectForKey: @"CFBundleVersion"]];

    NSDictionary * info = [Utilities readPropertyListData: data];
    
    for(NSString * key in info)
      if([key isEqualToString: @"Application Updates"])
        for(NSDictionary * attributes in [info objectForKey: key])
          {
          NSString * bundleId =
            [attributes objectForKey: @"CFBundleIdentifier"];
          
          if([appBundleId isEqualToString: bundleId])
            {
            NSNumber * version =
              [numberFormatter
                numberFromString:
                  [attributes objectForKey: @"CFBundleVersion"]];
            
            if([version intValue] > [appVersion intValue])
              [self
                presentUpdate:
                  [NSURL URLWithString: [attributes objectForKey: @"URL"]]];
            }
        }
      
    [numberFormatter release];
    }
  }

// Show the update dialog.
- (void) presentUpdate: (NSURL *) url
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert setMessageText: NSLocalizedString(@"Update Available", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  [alert setInformativeText: NSLocalizedString(@"updateavailable", NULL)];

  // This is the rightmost, first, default button.
  [alert
    addButtonWithTitle: NSLocalizedString(@"Quit and go to update", NULL)];

  [alert addButtonWithTitle: NSLocalizedString(@"Skip", NULL)];

  NSInteger result = [alert runModal];

  if(result == NSAlertFirstButtonReturn)
    {
    [[NSWorkspace sharedWorkspace] openURL: url];
    
    [[NSApplication sharedApplication] terminate: self];
    }
    
  [alert release];
  }

// Instruct the user.
- (void) showInstructions
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: NSLocalizedString(@"EtreCheck Report", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  [alert setInformativeText: NSLocalizedString(@"etrecheckreport", NULL)];

  // This is the rightmost, first, default button.
  [alert
    addButtonWithTitle:
      NSLocalizedString(@"Go to Apple support forums", NULL)];

  [alert addButtonWithTitle: NSLocalizedString(@"Continue", NULL)];

  NSInteger result = [alert runModal];

  if(result == NSAlertFirstButtonReturn)
    [[NSWorkspace sharedWorkspace]
      openURL:
        [NSURL
          URLWithString: NSLocalizedString(@"applesupportforums", NULL)]];
    
  [alert release];
  }

// Collect the user message.
- (void) collectUserMessage
  {
  BOOL dontShowUserMessage =
    [[NSUserDefaults standardUserDefaults]
      boolForKey: @"dontshowusermessage"];

  if(dontShowUserMessage)
    {
    [self start: self];
    return;
    }
    
  [[NSApplication sharedApplication]
    beginSheet: self.userMessgePanel
    modalForWindow: self.window
    modalDelegate: self
    didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
    contextInfo: nil];
  }
  
- (void) didEndSheet: (NSWindow *) sheet
  returnCode: (NSInteger) returnCode contextInfo: (void *) contextInfo
  {
  [sheet orderOut: self];
  }

// Start the report.
- (IBAction) start: (id) sender
  {
  [[NSApplication sharedApplication] endSheet: self.userMessgePanel];
  
  dispatch_async(
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    ^{
      [self collectInfo];
    });
  }

// Cancel the report.
- (IBAction) cancel: (id) sender
  {
  [[NSApplication sharedApplication] endSheet: self.userMessgePanel];

  [[NSApplication sharedApplication] terminate: sender];
  }

// Allow the program to close when closing the window.
- (BOOL) applicationShouldTerminateAfterLastWindowClosed:
  (NSApplication *) sender
  {
  return YES;
  }

// Fire it up.
- (void) collectInfo
  {
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  
  NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateStyle: NSDateFormatterLongStyle];
  [dateFormatter setTimeStyle: NSDateFormatterLongStyle];
  [dateFormatter setLocale: [NSLocale currentLocale]];
  NSString * dateString = [dateFormatter stringFromDate: [NSDate date]];
  [dateFormatter release];

  NSBundle * bundle = [NSBundle mainBundle];
  
  if([self.userMessage length])
    {
    [self.log
      appendString: NSLocalizedString(@"Problem description:\n", NULL)
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
      
    [self.log
      appendAttributedString:
        [self.userMessage attributedStringByTrimmingWhitespace]];
    
    [self.log appendString: @"\n\n"];
    }
    
  [self.log
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(
            @"EtreCheck version: %@ (%@)\nReport generated %@\n\n", NULL),
            [bundle
              objectForInfoDictionaryKey: @"CFBundleShortVersionString"],
            [bundle objectForInfoDictionaryKey: @"CFBundleVersion"],
            dateString]
    attributes:
      [NSDictionary
       dictionaryWithObjectsAndKeys:
         [[Utilities shared] boldFont], NSFontAttributeName, nil]];

  [self setupNotificationHandlers];
  
  [self.progress startAnimation: self];
  [self.spinner startAnimation: self];
  
  Checker * checker = [Checker new];
  
  [self.log appendAttributedString: [checker check]];
  
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      [self displayOutput];
    });
    
  [checker release];
  [LaunchdCollector cleanup];
  
  [pool drain];
  }

// Setup notification handlers.
- (void) setupNotificationHandlers
  {
  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(statusUpdated:)
    name: kStatusUpdate
    object: nil];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(progressUpdated:)
    name: kProgressUpdate
    object: nil];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(minorProgressUpdated:)
    name: kMinorProgressUpdate
    object: nil];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(applicationFound:)
    name: kFoundApplication
    object: nil];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(showMachineIcon:)
    name: kShowMachineIcon
    object: nil];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(showCollectionStatus:)
    name: kCollectionStatus
    object: nil];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(showDemonAgent:)
    name: kShowDemonAgent
    object: nil];
  }

// Handle a status update.
- (void) statusUpdated: (NSNotification *) notification
  {
  NSMutableAttributedString * newStatus = [self.displayStatus mutableCopy];
  
  [newStatus
    appendString:
      [NSString stringWithFormat: @"%@\n", [notification object]]];

  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      NSMutableAttributedString * status = [newStatus copy];
      self.displayStatus = status;

      [status release];
      
      [[self.statusView animator]
        scrollRangeToVisible:
          NSMakeRange(self.statusView.string.length, 0)];
    });
  
  [newStatus release];
  }
  
// Handle a progress update.
- (void) progressUpdated: (NSNotification *) notification
  {
  if([self.progress isIndeterminate])
    [self.progress setIndeterminate: NO];
    
  self.currentProgressIncrement = [[notification object] doubleValue];
  
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      // Try to make Snow Leopard update.
      if((self.currentProgressIncrement - [self.progress doubleValue]) > 1)
        [self.progress setNeedsDisplay: YES];

      // Snow Leopard doesn't like animations with CA layers.
      // Beat it with a rubber hose.
      [self.progress setHidden: YES];
      [self.progress setDoubleValue: self.currentProgressIncrement];
      [self.progress setHidden: NO];
      [self.progress startAnimation: self];
    });
  }

// Handle an application found.
- (void) applicationFound: (NSNotification *) notification
  {
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      [self.applicationIcon transitionToImage: [notification object]];
    });
  }

// Show a machine icon.
- (void) showMachineIcon: (NSNotification *) notification
  {
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      [self.machineIcon transitionToImage: [notification object]];
    });
  }

// Handle a minor progress update.
- (void) minorProgressUpdated: (NSNotification *) notification
  {
  double amount = [[notification object] doubleValue];
  
  amount = amount/100.0 * self.currentProgressIncrement;
  
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      self.progress.doubleValue = self.currentProgressIncrement + amount;
    });
  }

// Show the coarse collection status.
- (void) showCollectionStatus: (NSNotification *) notification
  {
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      // Move the spinner to make room for the status.
      NSString * status = [notification object];
      
      NSRect oldRect =
        [self.collectionStatus
          boundingRectWithSize: NSMakeSize(1000, 1000)
          options:0
          attributes:
            @{
              NSFontAttributeName: [NSFont labelFontOfSize: 12.0]
            }];

      NSRect newRect =
        [status
          boundingRectWithSize: NSMakeSize(1000, 1000)
          options:0
          attributes:
            @{
              NSFontAttributeName: [NSFont labelFontOfSize: 12.0]
            }];

      NSRect frame = [self.spinner frame];
      
      if(oldRect.size.width > 0)
        frame.origin.x -= 24;
      
      frame.origin.x -= oldRect.size.width / 2;
      frame.origin.x += newRect.size.width / 2;
      frame.origin.x += 24;
      
      // Snow Leopard doesn't like progress indicators with CA layers.
      // Beat it with a rubber hose.
      [self.spinner setHidden: YES];
      [self.spinner setFrame: frame];
      [self.spinner setHidden: NO];
      
      self.collectionStatus = [notification object];
    });
  }

// Show the demon and agent animation.
- (void) showDemonAgent: (NSNotification *) notification
  {
  NSRect demonStartFrame = [self.demonImage frame];
  NSRect demonEndFrame = demonStartFrame;
  
  demonEndFrame.origin.x -= 45;

  NSRect agentStartFrame = [self.agentImage frame];
  NSRect agentEndFrame = agentStartFrame;
  
  agentEndFrame.origin.x += 45;

  [self animateDemon: demonEndFrame];
  [self animateDemon: demonStartFrame agent: agentEndFrame];
  [self animateAgent: agentStartFrame];
  }

// Show the demon.
- (void) animateDemon: (NSRect) demonEndFrame
  {
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
    dispatch_get_main_queue(),
    ^{
      [NSAnimationContext beginGrouping];
      
      [[NSAnimationContext currentContext] setDuration: 0.5];
      
      [[self.demonImage animator] setFrame: demonEndFrame];
      
      [NSAnimationContext endGrouping];
    });
  }

// Hide the demon and show the agent.
- (void) animateDemon: (NSRect) demonStartFrame agent: (NSRect) agentEndFrame
  {
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7 * NSEC_PER_SEC)),
    dispatch_get_main_queue(),
    ^{
      [NSAnimationContext beginGrouping];
      
      [[NSAnimationContext currentContext] setDuration: 0.5];
      
      [[self.demonImage animator] setFrame: demonStartFrame];
      [[self.agentImage animator] setFrame: agentEndFrame];

      [NSAnimationContext endGrouping];
    });
  }

// Hide the agent.
- (void) animateAgent: (NSRect) agentStartFrame
  {
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(11 * NSEC_PER_SEC)),
    dispatch_get_main_queue(),
    ^{
      [NSAnimationContext beginGrouping];
      
      [[NSAnimationContext currentContext] setDuration: 0.5];
      
      [[self.agentImage animator] setFrame: agentStartFrame];

      [NSAnimationContext endGrouping];
    });
  }

// Show the output pane.
- (void) displayOutput
  {
  NSData * rtfData =
    [self.log
      RTFFromRange: NSMakeRange(0, [self.log length])
      documentAttributes: nil];
  
  NSRange range =
    NSMakeRange(0, [[self.logView textStorage] length]);

  [self.logView
    replaceCharactersInRange: range withRTF: rtfData];
    
  [self hideAnimationView];
  
  [self showReportView];
  }

// Hide the animation view.
- (void) hideAnimationView
  {
  // Hide the progress bar in Snow Leopard.
  NSUInteger majorOSVersion =
    [[SystemInformation sharedInformation] majorOSVersion];
    
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      if(majorOSVersion < kLion)
        {
        [self.progress stopAnimation: self];
        [self.spinner stopAnimation: self];
        }
      
      [self.logView setHidden: NO];
    });
  
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)),
    dispatch_get_main_queue(),
    ^{
      [NSAnimationContext beginGrouping];
      
      [[NSAnimationContext currentContext] setDuration: 1.0];
      
      [[self.animationView animator] setAlphaValue: 0];
        
      [[self.reportView animator] setAlphaValue: 1];

      [NSAnimationContext endGrouping];
    });
  }

// Show the report view.
- (void) showReportView
  {
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
    dispatch_get_main_queue(),
    ^{
      [NSAnimationContext beginGrouping];
      
      [[NSAnimationContext currentContext] setDuration: 1.0];
      
      [self.window makeFirstResponder: self.logView];
      
      NSRect frame = [self.window frame];
      
      if(frame.size.height < 512)
        {
        frame.origin.y -= (512 - frame.size.height)/4;
        frame.size.height = 512;
        }
        
      [window setFrame: frame display: YES animate: YES];
      
      [NSAnimationContext endGrouping];
      
      [[self.logView enclosingScrollView] setHasVerticalScroller: YES];
      [self.window setShowsResizeIndicator: YES];
      [self.window
        setStyleMask: [self.window styleMask] | NSResizableWindowMask];
    });
  }

// Copy the report to the clipboard.
- (IBAction) copyToClipboard: (id) sender
  {
  NSPasteboard * pasteboard = [NSPasteboard generalPasteboard];
 
  [pasteboard clearContents];
 
  NSError * error = nil;
  
  NSData * rtfData =
    [self.log
      dataFromRange: NSMakeRange(0, [self.log length])
      documentAttributes:
        @
          {
          NSDocumentTypeDocumentAttribute : NSRTFTextDocumentType
          }
      error: & error];

  [pasteboard setData: rtfData forType: NSPasteboardTypeRTF];
  
  [self showInstructions];
  }
  
// Show a custom about panel.
- (IBAction) showAbout: (id) sender
  {
  [[NSApplication sharedApplication]
    orderFrontStandardAboutPanelWithOptions: @{@"Version" : @""}];
  }

// Go to the Etresoft web site.
- (IBAction) gotoEtresoft: (id) sender
  {
  [[NSWorkspace sharedWorkspace]
    openURL: [NSURL URLWithString: @"http://www.etresoft.com"]];
  }

// Display more info.
- (IBAction) moreInfo: (id) sender
  {
  [[NSWorkspace sharedWorkspace]
    openURL:
      [NSURL URLWithString: @"http://www.etresoft.com/etrecheck_story"]];
  }

// Show the log window.
- (IBAction) showLog: (id) sender
  {
  [self.logWindow makeKeyAndOrderFront: sender];
  }

// Shwo the EtreCheck window.
- (IBAction) showEtreCheck: (id) sender
  {
  [self.window makeKeyAndOrderFront: sender];
  }

// Confirm cancel.
- (IBAction) confirmCancel: (id) sender
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: NSLocalizedString(@"Confirm cancellation", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  [alert
    setInformativeText:
      NSLocalizedString(
        @"Are you sure you want to cancel this EtreCheck report?", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"No, continue", NULL)];

  [alert addButtonWithTitle: NSLocalizedString(@"Yes, cancel", NULL)];

  NSInteger result = [alert runModal];

  if(result == NSAlertSecondButtonReturn)
    [self cancel: sender];
    
  [alert release];
  }

// Save the EtreCheck report.
- (IBAction) saveReport: (id) sender
  {
  NSSavePanel * savePanel = [NSSavePanel savePanel];
  
  [savePanel setAllowedFileTypes: @[@"rtf"]];
  
  NSInteger result = [savePanel runModal];
  
  if(result == NSFileHandlingPanelOKButton)
    {
    NSError * error = nil;
    
    NSData * rtfData =
      [self.log
        dataFromRange: NSMakeRange(0, [self.log length])
        documentAttributes:
          @
            {
            NSDocumentTypeDocumentAttribute : NSRTFTextDocumentType
            }
        error: & error];
      
    if(rtfData)
      [rtfData writeToURL: [savePanel URL] atomically: YES];
    }
  }

@end
