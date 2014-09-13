/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "SafariExtensionsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "SystemInformation.h"
#import "Utilities.h"

// TODO: Get display name from plist file.

// Collect Safari extensions.
@implementation SafariExtensionsCollector

@synthesize updates = myUpdates;
@synthesize settings = mySettings;

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    self.name = @"safariextensions";
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  self.settings = nil;
  self.updates = nil;
  
  [super dealloc];
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking Safari extensions", NULL)];

  NSString * userSafariExtensionsDir =
    [NSHomeDirectory()
      stringByAppendingPathComponent: @"Library/Safari/Extensions"];

  NSUserDefaults * defaults = [[NSUserDefaults alloc] init];
  
  self.settings =
    [defaults
      persistentDomainForName:
        [userSafariExtensionsDir
          stringByAppendingPathComponent: @"extensions"]];

  [defaults release];
  
  // Get extension updates.
  [self collectUpdates];
  
  NSArray * currentExtensions =
    [self.settings objectForKey: @"Installed Extensions"];
  
  // Print the extensions.
  if([currentExtensions count])
    {
    [self.result
      appendAttributedString: [self buildTitle: @"Safari Extensions:"]];

    for(NSDictionary * extension in currentExtensions)
      [self printExtension: extension];
    
    [self.result appendCR];
    }
  }

// Collect extension updates.
- (void) collectUpdates
  {
  NSDictionary * availableUpdates =
    [self.settings objectForKey: @"Available Updates"];
  
  NSArray * updatesList = nil;
  
  if([availableUpdates respondsToSelector: @selector(objectForKey:)])
    updatesList = [availableUpdates objectForKey: @"Updates List"];
    
  self.updates = [NSMutableDictionary dictionary];
  
  if([updatesList count])
    {
    for(NSDictionary * update in updatesList)
      {
      NSString * urlString = [update objectForKey: @"Update URL"];
      NSURL * url = [NSURL URLWithString: urlString];
      
      NSString * name = [url lastPathComponent];
      
      [self.updates setObject: urlString forKey: name];
      }
    }
  }

// Print a Safari extension.
- (void) printExtension: (NSDictionary *) extension
  {
  NSNumber * enabled = [extension objectForKey: @"Enabled"];
  
  NSString * archiveName =
    [extension objectForKey: @"Archive File Name"];
  
  NSString * name = [extension objectForKey: @"Bundle Directory Name"];
  
  if(!name)
    name = archiveName;
  
  name = [name stringByDeletingPathExtension];
  
  NSString * updateURL = [self.updates objectForKey: archiveName];
  
  [self.result
    appendString: [NSString stringWithFormat: @"\t%@ ", name]];
    
  if(![enabled intValue])
    [self.result appendString: NSLocalizedString(@"(Disabled) ", NULL)];

  if(updateURL)
    [self.result
      appendString: NSLocalizedString(@"(Update available)", NULL)
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
          NSForegroundColorAttributeName : [[Utilities shared] blue],
          NSLinkAttributeName : updateURL
        }];
    
  [self.result appendString: @"\n"];
  }

@end
