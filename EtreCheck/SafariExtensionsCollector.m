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
      NSString * compositeIdentifier = [update objectForKey: @"Identifier"];
      
      NSMutableArray * identifierParts =
        [NSMutableArray
          arrayWithArray:
            [compositeIdentifier componentsSeparatedByString: @"-"]];
      
      [identifierParts removeLastObject];
      
      NSString * identifier =
        [identifierParts componentsJoinedByString: @"-"];
      
      NSString * urlString = [update objectForKey: @"Update URL"];

      [self.updates setObject: urlString forKey: identifier];
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
  
  NSDictionary * plist = [self extensionInfoPList: name];
  
  NSString * humanReadableName = [self humanReadableExtensionName: plist];
  
  if(humanReadableName)
    name = humanReadableName;
    
  NSString * identifier = [plist objectForKey: @"CFBundleIdentifier"];
  
  NSString * updateURL = [self.updates objectForKey: identifier];
  
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

// Read the extension plist dictionary.
- (NSDictionary *) extensionInfoPList: (NSString *) extensionName
  {
  NSString * userSafariExtensionsDir =
    [NSHomeDirectory()
      stringByAppendingPathComponent: @"Library/Safari/Extensions"];

  NSString * extensionPath =
    [userSafariExtensionsDir stringByAppendingPathComponent: extensionName];
  
  return
    [self
      readSafariExtensionPropertyList:
        [extensionPath stringByAppendingPathExtension: @"safariextz"]];
  }

// Get the human readable extension name from the plist dictionary.
- (NSString *) humanReadableExtensionName: (NSDictionary *) plist
  {
  NSString * name = [plist objectForKey: @"CFBundleDisplayName"];
    
  if(name)
    return name;
  
  return nil;
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
