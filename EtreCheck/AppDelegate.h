/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import <Cocoa/Cocoa.h>

@class SlideshowView;
@class DetailManager;

@interface AppDelegate : NSObject
  <NSApplicationDelegate, NSUserNotificationCenterDelegate>
  {
  NSWindow * window;
  NSWindow * myLogWindow;
  NSView * myAnimationView;
  NSView * myReportView;
  NSProgressIndicator * myProgress;
  NSProgressIndicator * mySpinner;
  NSTextView * myStatusView;
  NSTextView * logView;
  NSButton * toClipboard;
  NSButton * moreInfo;
  NSAttributedString * myDisplayStatus;
  NSMutableAttributedString * log;
  double myCurrentProgressIncrement;
  NSTimer * myProgressTimer;
  SlideshowView * myMachineIcon;
  SlideshowView * myApplicationIcon;
  NSImageView * myMagnifyingGlass;
  NSImageView * myMagnifyingGlassShade;
  NSImageView * myFinderIcon;
  NSImageView * myDemonImage;
  NSImageView * myAgentImage;
  NSString * myCollectionStatus;
  NSAttributedString * myUserMessage;
  NSWindow * myUserMessagePanel;

  NSMutableDictionary * launchdStatus;
  NSMutableSet * appleLaunchd;
  
  BOOL launchDFail;
  BOOL launchDAvailable;
  
  DetailManager * myDetailManager;
  }
  
@property (retain) IBOutlet NSWindow * window;
@property (retain) IBOutlet NSWindow * logWindow;
@property (retain) IBOutlet NSView * animationView;
@property (retain) IBOutlet NSView * reportView;
@property (retain) IBOutlet NSProgressIndicator * progress;
@property (retain) IBOutlet NSProgressIndicator * spinner;
@property (retain) IBOutlet NSTextView * statusView;
@property (retain) IBOutlet NSTextView * logView;
@property (retain) IBOutlet NSButton * toClipboard;
@property (retain) IBOutlet NSButton * moreInfo;
@property (retain) NSAttributedString * displayStatus;
@property (retain) NSMutableAttributedString * log;
@property (assign) double currentProgressIncrement;
@property (retain) NSTimer * progressTimer;
@property (retain) IBOutlet SlideshowView * machineIcon;
@property (retain) IBOutlet SlideshowView * applicationIcon;
@property (retain) IBOutlet NSImageView * magnifyingGlass;
@property (retain) IBOutlet NSImageView * magnifyingGlassShade;
@property (retain) IBOutlet NSImageView * finderIcon;
@property (retain) IBOutlet NSImageView * demonImage;
@property (retain) IBOutlet NSImageView * agentImage;
@property (retain) NSString * collectionStatus;
@property (retain) NSAttributedString * userMessage;
@property (retain) IBOutlet NSWindow * userMessgePanel;
@property (retain) IBOutlet DetailManager * detailManager;

// Start the report.
- (IBAction) start: (id) sender;

// Cancel the report.
- (IBAction) cancel: (id) sender;

// Copy the report to the clipboard.
- (IBAction) copyToClipboard: (id) sender;

// Show a custom about panel.
- (IBAction) showAbout: (id) sender;

// Go to the Etresoft web site.
- (IBAction) gotoEtresoft: (id) sender;

// Display more info.
- (IBAction) moreInfo: (id) sender;

// Show the log window.
- (IBAction) showLog: (id) sender;

// Show the EtreCheck window.
- (IBAction) showEtreCheck: (id) sender;

// Confirm cancel.
- (IBAction) confirmCancel: (id) sender;

// Save the EtreCheck report.
- (IBAction) saveReport: (id) sender;

@end
