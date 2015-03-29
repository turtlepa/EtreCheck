/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "SafariExtensionsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"

#define kIdentifier @"identifier"
#define kHumanReadableName @"humanreadablename"
#define kFileName @"filename"

// Collect Safari extensions.
@implementation SafariExtensionsCollector

@synthesize extensions = myExtensions;

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"safariextensions";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);

    myExtensions = [NSMutableDictionary new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  self.extensions = nil;
  
  [super dealloc];
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Checking Safari extensions", NULL)];

  [self collectArchives];

  // Print the extensions.
  if([self.extensions count])
    {
    [self.result appendAttributedString: [self buildTitle]];

    for(NSString * name in self.extensions)
      [self printExtension: [self.extensions objectForKey: name]];
    
    [self.result appendCR];
    }

  dispatch_semaphore_signal(self.complete);
  }

// Collect extension archives.
- (void) collectArchives
  {
  NSString * userSafariExtensionsDir =
    [NSHomeDirectory()
      stringByAppendingPathComponent: @"Library/Safari/Extensions"];

  NSArray * args =
    @[
      userSafariExtensionsDir,
      @"-iname",
      @"*.safariextz"];

  NSData * data = [Utilities execute: @"/usr/bin/find" arguments: args];
  
  NSArray * paths = [Utilities formatLines: data];
  
  for(NSString * path in paths)
    {
    NSString * name = [self extensionName: path];
      
    NSDictionary * plist = [self readSafariExtensionPropertyList: path];

    [self createExtensionsFromPlist: plist name: name];
    }
  }

// Get the extension name, less the uniquifier.
- (NSString *) extensionName: (NSString *) path
  {
  if(!path)
    return nil;
    
  NSString * name =
    [[path lastPathComponent] stringByDeletingPathExtension];
    
  NSMutableArray * parts =
    [NSMutableArray
      arrayWithArray: [name componentsSeparatedByString: @"-"]];
    
  if([parts count] > 1)
    if([[parts lastObject] integerValue] > 1)
      [parts removeLastObject];
    
  return [parts componentsJoinedByString: @"-"];
  }

// Create an extension dictionary from a plist.
- (void) createExtensionsFromPlist: (NSDictionary *) plist
  name: (NSString *) name
  {
  NSString * humanReadableName =
    [plist objectForKey: @"CFBundleDisplayName"];
  
  if(!humanReadableName)
    humanReadableName = name;
    
  NSString * identifier = [plist objectForKey: @"CFBundleIdentifier"];
  
  if(!identifier)
    identifier = name;
    
  NSMutableDictionary * extension = [self.extensions objectForKey: name];
  
  if(!extension)
    {
    extension = [NSMutableDictionary dictionary];
    
    [self.extensions setObject: extension forKey: name];
    }
    
  [extension setObject: humanReadableName forKey: kHumanReadableName];
  [extension setObject: identifier forKey: kIdentifier];
  [extension setObject: name forKey: kFileName];
  }

// Print a Safari extension.
- (void) printExtension: (NSDictionary *) extension
  {
  NSString * humanReadableName =
    [extension objectForKey: kHumanReadableName];
  
  [self.result
    appendString:
      [NSString stringWithFormat: @"    %@", humanReadableName]];
    
  bool adware = [[Model model] isAdwareExtension: humanReadableName];
  
  if([[Model model] isAdwareExtension: [extension objectForKey: kFileName]])
    adware = true;
    
  if(adware)
    {
    [self.result appendString: @" "];
    
    // Add this adware extension under the "extension" category so only it
    // will be printed.
    [[[Model model] adwareFiles]
      setObject: @"extension" forKey: humanReadableName];
    [[Model model] setAdwareFound: YES];

    NSAttributedString * removeLink =
      [self generateRemoveAdwareLink: @"extension"];

    if(removeLink)
      [self.result appendAttributedString: removeLink];
    else
      [self.result
        appendString: NSLocalizedString(@"Adware!", NULL)
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
    }

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
