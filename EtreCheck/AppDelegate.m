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
#import "Model.h"
#import "NSAttributedString+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "DetailManager.h"
#import "HelpManager.h"

NSComparisonResult compareViews(id view1, id view2, void * context);

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
@synthesize nextProgressIncrement = myNextProgressIncrement;
@synthesize progressTimer = myProgressTimer;
@synthesize machineIcon = myMachineIcon;
@synthesize applicationIcon = myApplicationIcon;
@synthesize magnifyingGlass = myMagnifyingGlass;
@synthesize magnifyingGlassShade = myMagnifyingGlassShade;
@synthesize finderIcon = myFinderIcon;
@synthesize demonImage = myDemonImage;
@synthesize agentImage = myAgentImage;
@synthesize collectionStatus = myCollectionStatus;
@synthesize reportView = myReportView;
@synthesize animationView = myAnimationView;
@synthesize userMessage = myUserMessage;
@synthesize userMessgePanel = myUserMessagePanel;
@synthesize detailManager = myDetailManager;
@synthesize helpManager = myHelpManager;
@synthesize adwareManager = myAdwareManager;

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
  
  [self.window.contentView addSubview: self.animationView];
  
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
        
  [self.magnifyingGlass setHidden: NO];
    
  [self.finderIcon setImage: [[Utilities shared] FinderIcon]];
  [self.demonImage setHidden: NO];
  [self.agentImage setHidden: NO];
  
  //[self.logView setHidden: YES];
  
  [self.animationView
    sortSubviewsUsingFunction: compareViews context: self];
  
  // Set delegate for notification center.
  [[NSUserNotificationCenter defaultUserNotificationCenter]
    setDelegate: self];

  // Handle my own "etrecheck:" URLs.
  NSAppleEventManager * appleEventManager =
    [NSAppleEventManager sharedAppleEventManager];
  
  [appleEventManager
    setEventHandler: self
    andSelector: @selector(handleGetURLEvent:withReplyEvent:)
    forEventClass:kInternetEventClass
    andEventID: kAEGetURL];
  
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)),
    dispatch_get_main_queue(),
    ^{
      [self collectUserMessage];
    });
  }

// Handle an "etrecheck:" URL.
- (void) handleGetURLEvent: (NSAppleEventDescriptor *) event
  withReplyEvent: (NSAppleEventDescriptor *) reply
  {
  NSString * urlString =
    [[event paramDescriptorForKeyword: keyDirectObject] stringValue];
  
  NSURL * url = [NSURL URLWithString: urlString];
    
  if([[url scheme] isEqualToString: @"etrecheck"])
    {
    NSString * manager = [url host];
    
    if([manager isEqualToString: @"detail"])
      [self.detailManager showDetail: [[url path] substringFromIndex: 1]];
    else if([manager isEqualToString: @"help"])
      [self.helpManager showDetail: [[url path] substringFromIndex: 1]];
    else if([manager isEqualToString: @"adware"])
      [self.adwareManager showDetail: [[url path] substringFromIndex: 1]];
    }
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

    NSDictionary * info = [NSDictionary readPropertyListData: data];
    
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
  bool dontShowUserMessage =
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
  
  [self startProgressTimer];
  
  dispatch_async(
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    ^{
      [self collectInfo];
    });
  }

// Start the progress timer.
- (void) startProgressTimer
  {
  self.progressTimer =
    [NSTimer
      scheduledTimerWithTimeInterval: .2
      target: self
      selector: @selector(fireProgressTimer:)
      userInfo: nil
      repeats: YES];
  }

// Progress timer.
- (void) fireProgressTimer: (NSTimer *) timer
  {
  double current = [self.progress doubleValue];
  
  current = current + 0.5;
    
  if(current > self.nextProgressIncrement)
    return;
    
  [self updateProgress: current];
  
  if(current >= 100)
    [timer invalidate];
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
  
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      [self.progress startAnimation: self];
      [self.spinner startAnimation: self];
    });

  [self setupNotificationHandlers];
  
  Checker * checker = [Checker new];
  
  NSAttributedString * results = [checker check];
  
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      [self printEtreCheckHeader];
  
      [self.log appendAttributedString: results];
  
      [self displayOutput];
    });
    
  [checker release];
  [LaunchdCollector cleanup];
  
  [pool drain];
  }

// Print the EtreCheck header.
- (void) printEtreCheckHeader
  {
  [self printProblemDescription];
  
  NSBundle * bundle = [NSBundle mainBundle];
  
  [self.log
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(
            @"EtreCheck version: %@ (%@)\nReport generated %@\n", NULL),
            [bundle
              objectForInfoDictionaryKey: @"CFBundleShortVersionString"],
            [bundle objectForInfoDictionaryKey: @"CFBundleVersion"],
            [self currentDate]]
    attributes:
      [NSDictionary
       dictionaryWithObjectsAndKeys:
         [[Utilities shared] boldFont], NSFontAttributeName, nil]];
    
  [self.log
    appendString: NSLocalizedString(@"downloadetrecheck", NULL)
    attributes:
      [NSDictionary
       dictionaryWithObjectsAndKeys:
         [[Utilities shared] boldFont], NSFontAttributeName, nil]];

  [self.log
    appendAttributedString:
      [Utilities
        buildURL: @"http://etresoft.com/etrecheck"
        title: @"http://etresoft.com/etrecheck"]];
    
  [self.log appendString: @"\n\n"];
  
  [self printLinkInstructions];
  
  [self printErrors];
  }

// Print the problem description.
- (void) printProblemDescription
  {
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
  }

// Print link instructions.
- (void) printLinkInstructions
  {
  [self.log
    appendRTFData:
      [NSData
        dataWithContentsOfFile:
          [[NSBundle mainBundle]
            pathForResource: @"linkhelp" ofType: @"rtf"]]];

  if([[Model model] adwareFound])
    [self.log
      appendRTFData:
        [NSData
          dataWithContentsOfFile:
            [[NSBundle mainBundle]
              pathForResource: @"adwarehelp" ofType: @"rtf"]]];

  [self.log appendString: @"\n"];
  }

// Print errors during EtreCheck itself.
- (void) printErrors
  {
  NSArray * terminatedTasks = [[Model model] terminatedTasks];
  
  if(terminatedTasks.count)
    {
    }
  }

// Get the current date as a string.
- (NSString *) currentDate
  {
  NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateStyle: NSDateFormatterShortStyle];
  [dateFormatter setTimeStyle: NSDateFormatterShortStyle];
  [dateFormatter setLocale: [NSLocale localeWithLocaleIdentifier: @"en"]];
  
  NSString * dateString = [dateFormatter stringFromDate: [NSDate date]];
  
  [dateFormatter release];

  return dateString;
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
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      [self updateProgress: self.nextProgressIncrement];
      
      self.nextProgressIncrement = [[notification object] doubleValue];
    });
  }

- (void) updateProgress: (double) amount
  {
  // Try to make Snow Leopard update.
  if((self.nextProgressIncrement - [self.progress doubleValue]) > 1)
    [self.progress setNeedsDisplay: YES];

  if([self.progress isIndeterminate])
    [self.progress setIndeterminate: NO];
    
  // Snow Leopard doesn't like animations with CA layers.
  // Beat it with a rubber hose.
  [self.progress setHidden: YES];
  [self.progress setDoubleValue: amount];
  [self.progress setHidden: NO];
  [self.progress startAnimation: self];
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
  [self.progressTimer invalidate];
  
  NSData * rtfData =
    [self.log
      RTFFromRange: NSMakeRange(0, [self.log length])
      documentAttributes: nil];
  
  NSRange range =
    NSMakeRange(0, [[self.logView textStorage] length]);

  [self.logView
    replaceCharactersInRange: range withRTF: rtfData];
    
  [NSAnimationContext beginGrouping];
  
  [[NSAnimationContext currentContext] setDuration: 1.0];
  
  [self.window.contentView addSubview: self.reportView];
  
  [[self.animationView animator] removeFromSuperview];
  
  [NSAnimationContext endGrouping];
  
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
    dispatch_get_main_queue(),
    ^{
      [self resizeReportView];
    });
  }

// Resize the report view.
- (void) resizeReportView
  {
  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(didScroll:)
    name: NSViewBoundsDidChangeNotification
    object: [[self.logView enclosingScrollView] contentView]];
  
  [[[self.logView enclosingScrollView] contentView]
    setPostsBoundsChangedNotifications: YES];

  [self.window makeFirstResponder: self.logView];
  
  NSRect frame = [self.window frame];
  
  if(frame.size.height < 512)
    {
    frame.origin.y -= (512 - frame.size.height)/2;
    frame.size.height = 512;
    }
    
  [window setFrame: frame display: YES animate: YES];
  
  [[self.logView enclosingScrollView] setHasVerticalScroller: YES];
  [self.window setShowsResizeIndicator: YES];
  [self.window
    setStyleMask: [self.window styleMask] | NSResizableWindowMask];
  
  [self notify];

  [self.logView
    scrollRangeToVisible: NSMakeRange([self.log length] - 2, 1)];
  [self.logView scrollRangeToVisible: NSMakeRange(0, 1)];
  }

// Handle a scroll change in the report view.
- (void) didScroll: (NSNotification *) notification
  {
  [self.detailManager closeDetail: self];
  [self.helpManager closeDetail: self];
  [self.adwareManager closeDetail: self];
  }

// Notify the user that the report is done.
- (void) notify
  {
  if(![NSUserNotificationCenter class])
    return;
    
  // Notify the user.
  NSUserNotification * notification = [[NSUserNotification alloc] init];
    
  notification.title = @"Etrecheck";
  notification.informativeText =
    NSLocalizedString(@"Report complete", NULL);
  
  // TODO: Do something clever with sound and notifications.
  notification.soundName = NSUserNotificationDefaultSoundName;
  
  [[NSUserNotificationCenter defaultUserNotificationCenter]
    deliverNotification: notification];
    
  [notification release];
  }

// Display web site when the user clicks on a notification.
- (void) userNotificationCenter: (NSUserNotificationCenter *) center
  didActivateNotification: (NSUserNotification *) notification
  {
  if([self.window isMiniaturized])
    [self.window deminiaturize: self];
    
  [self.window makeKeyAndOrderFront: self];
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

NSComparisonResult compareViews(id view1, id view2, void * context)
  {
  AppDelegate * self = (AppDelegate *)context;
  
  if(view1 == self.applicationIcon)
    return NSOrderedAscending;
    
  if(view1 == self.magnifyingGlass && view2 == self.applicationIcon)
    return NSOrderedDescending;
    
  if(view1 == self.magnifyingGlass)
    return NSOrderedAscending;
    
  if(view1 == self.magnifyingGlassShade)
    return NSOrderedAscending;

  return NSOrderedSame;
  }

