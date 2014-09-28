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
    
  dispatch_semaphore_signal(self.complete);
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
  
  NSString * humanReadableName = [self humanReadableExtensionName: name];
  
  if(humanReadableName)
    name = humanReadableName;
    
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

- (NSString *) humanReadableExtensionName: (NSString *) extensionName
  {
  NSString * userSafariExtensionsDir =
    [NSHomeDirectory()
      stringByAppendingPathComponent: @"Library/Safari/Extensions"];

  NSString * extensionPath =
    [userSafariExtensionsDir stringByAppendingPathComponent: extensionName];
  
  NSDictionary * plist =
    [self
      readSafariExtensionPropertyList:
        [extensionPath stringByAppendingPathExtension: @"safariextz"]];

  NSString * name = [plist objectForKey: @"CFBundleDisplayName"];
    
  if(name)
    return name;
  
  return extensionName;
  }

// Read a property list from a Safari extension.
- (id) readSafariExtensionPropertyList: (NSString *) path
  {
  NSString * tempDirectory =
    [self extractExtensionArchive: [path stringByResolvingSymlinksInPath]];

  NSDictionary * plist = [self findExtensionPlist: tempDirectory];
    
  [[NSFileManager defaultManager]
    removeItemAtPath: tempDirectory error: NULL];
    
  return plist;
  }

- (NSString *) extractExtensionArchive: (NSString *) path
  {
  NSString * resolvedPath = [path stringByResolvingSymlinksInPath];
  
  NSString * tempDirectory = [self createTemporaryDirectory];
  
  [[NSFileManager defaultManager]
    createDirectoryAtPath: tempDirectory
    withIntermediateDirectories: YES
    attributes: nil
    error: NULL];
  
  NSArray * args =
    @[
      @"-zxf",
      resolvedPath,
      @"-C",
      tempDirectory
    ];
  
  [Utilities execute: @"/usr/bin/xar" arguments: args];
  
  return tempDirectory;
  }

- (NSString *) createTemporaryDirectory
  {
  NSString * template =
    [NSTemporaryDirectory()
      stringByAppendingPathComponent: @"XXXXXXXXXXXX"];
  
  char * buffer = strdup([template fileSystemRepresentation]);
  
  mkdtemp(buffer);
  
  NSString * temporaryDirectory =
    [[NSFileManager defaultManager]
      stringWithFileSystemRepresentation: buffer length: strlen(buffer)];
  
  free(buffer);
  
  return temporaryDirectory;
  }

- (NSDictionary *) findExtensionPlist: (NSString *) directory
  {
  NSArray * args =
    @[
      directory,
      @"-name",
      @"Info.plist"
    ];
    
  NSData * infoPlistPathData =
    [Utilities execute: @"/usr/bin/find" arguments: args];

  NSString * infoPlistPathString =
    [[NSString alloc]
      initWithData: infoPlistPathData encoding: NSUTF8StringEncoding];
  
  NSString * infoPlistPath =
    [infoPlistPathString stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  
  [infoPlistPathString release];
  
  NSData * plistData =
    [Utilities execute: @"/bin/cat" arguments: @[infoPlistPath]];

  NSDictionary * plist = nil;
  
  if(plistData)
    {
    NSError * error;
    NSPropertyListFormat format;
    
    plist =
      [NSPropertyListSerialization
        propertyListWithData: plistData
        options: NSPropertyListImmutable
        format: & format
        error: & error];
    }
    
  return plist;
  }

@end
