/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Utilities.h"

// Assorted utilities.
@implementation Utilities

// Create some dynamic properties for the singleton.
@synthesize boldFont = myBoldFont;
@synthesize boldItalicFont = myBoldItalicFont;

@synthesize green = myGreen;
@synthesize blue = myBlue;
@synthesize red = myRed;
@synthesize gray = myGray;

@synthesize unknownMachineIcon = myUnknownMachineIcon;
@synthesize machineNotFoundIcon = myMachineNotFoundIcon;
@synthesize genericApplicationIcon = myGenericApplicationIcon;
@synthesize EtreCheckIcon = myEtreCheckIcon;
@synthesize FinderIcon = myFinderIcon;

// Return the singeton of shared values.
+ (Utilities *) shared
  {
  static Utilities * utilities = nil;
  
  static dispatch_once_t onceToken;
  
  dispatch_once(
    & onceToken,
    ^{
      utilities = [Utilities new];
    });
    
  return utilities;
  }

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    [self loadFonts];
    [self loadColours];
    [self loadIcons];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [myBoldFont release];
  [myBoldItalicFont release];

  [myGreen release];
  [myBlue release];
  [myGray release];
  [myRed release];
  
  [myFinderIcon release];
  [myEtreCheckIcon release];
  [myGenericApplicationIcon release];
  [myUnknownMachineIcon release];
  [myMachineNotFoundIcon release];
  
  return [super dealloc];
  }

// Load fonts.
- (void) loadFonts
  {
  NSFont * labelFont = [NSFont labelFontOfSize: 12.0];
  
  myBoldFont =
    [[NSFontManager sharedFontManager]
      convertFont: labelFont
      toHaveTrait: NSBoldFontMask];
    
  myBoldItalicFont =
    [NSFont fontWithName: @"Helvetica-BoldOblique" size: 12.0];
    
  [myBoldFont retain];
  [myBoldItalicFont retain];
  }

// Load colours.
- (void) loadColours
  {
  myGreen =
    [NSColor colorWithCalibratedRed: 0.2 green: 0.5 blue: 0.2 alpha: 0.0];
    
  myBlue =
    [NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.6 alpha: 0.0];

  myGray =
    [NSColor colorWithCalibratedRed: 0.4 green: 0.4 blue: 0.4 alpha: 0.0];

  myRed = [NSColor redColor];
  
  [myGreen retain];
  [myBlue retain];
  [myGray retain];
  [myRed retain];
  }

// Load icons.
- (void) loadIcons
  {
  NSString * resourceDirectory =
    @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/";
    
  myUnknownMachineIcon =
    [[NSImage alloc]
      initWithContentsOfFile:
        [resourceDirectory
          stringByAppendingPathComponent: @"GenericQuestionMarkIcon.icns"]];

  myMachineNotFoundIcon =
    [[NSImage alloc]
      initWithContentsOfFile:
        [resourceDirectory
          stringByAppendingPathComponent: @"public.generic-pc.icns"]];

  myGenericApplicationIcon =
    [[NSImage alloc]
      initWithContentsOfFile:
        [resourceDirectory
          stringByAppendingPathComponent: @"GenericApplicationIcon.icns"]];
  
  myEtreCheckIcon = [NSImage imageNamed: @"AppIcon"];
  
  myFinderIcon =
    [[NSImage alloc]
      initWithContentsOfFile:
        [resourceDirectory
          stringByAppendingPathComponent: @"FinderIcon.icns"]];
  }
  
// Execute an external program and return the results.
+ (NSData *) execute: (NSString *) program arguments: (NSArray *) args
  {
  // Create pipes for handling communication.
  NSPipe * outputPipe = [NSPipe new];
  NSPipe * errorPipe = [NSPipe new];
  
  // Create the task itself.
  NSTask * task = [NSTask new];
  
  // Send all task output to the pipe.
  [task setStandardOutput: outputPipe];
  [task setStandardError: errorPipe];
  
  [task setLaunchPath: program];

  if(args)
    [task setArguments: args];
  
  [task setCurrentDirectoryPath: @"/"];
  
  [task launch];
  
  NSData * result =
    [[[task standardOutput] fileHandleForReading] readDataToEndOfFile];
  
  NSData * error =
    [[[task standardError] fileHandleForReading] readDataToEndOfFile];

  [task release];
  [errorPipe release];
  [outputPipe release];
  
  if(![result length] && [error length])
    return error;
    
  return result;
  }

// Format text into an array of trimmed lines separated by newlines.
+ (NSArray *) formatLines: (NSData *) data
  {
  NSMutableArray * result = [NSMutableArray array];
  
  if(!data)
    return result;
    
  NSString * text =
    [[NSString alloc]
      initWithBytes: [data bytes]
      length: [data length]
      encoding: NSUTF8StringEncoding];
      
  NSArray * lines = [text componentsSeparatedByString: @"\n"];
  
  [text release];
  
  for(NSString * line in lines)
    {
    NSString * trimmedLine =
      [line
        stringByTrimmingCharactersInSet:
          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
          
    if([trimmedLine isEqualToString: @""])
      continue;
      
    [result addObject: trimmedLine];
    }
    
  return result;
  }

// Read a property list.
+ (id) readPropertyList: (NSString *) path
  {
  NSString * resolvedPath = [path stringByResolvingSymlinksInPath];
  
  return
    [self
      readPropertyListData: [NSData dataWithContentsOfFile: resolvedPath]];
  }
  
// Read a property list.
+ (id) readPropertyListData: (NSData *) data
  {
  if(data)
    {
    NSError * error;
    NSPropertyListFormat format;
    
    return
      [NSPropertyListSerialization
        propertyListWithData: data
        options: NSPropertyListImmutable
        format: & format
        error: & error];
    }
    
  return nil;
  }

// Redact any user names in a path.
+ (NSString *) cleanPath: (NSString *) path
  {
  NSString * username = NSUserName();
  
  NSRange range = [path rangeOfString: username];
  
  if(range.location == NSNotFound)
    return path;
    
  return
    [NSString
      stringWithFormat:
        NSLocalizedString(@"%@[redacted]%@", NULL),
        [path substringToIndex: range.location],
        [path substringFromIndex: range.location + range.length]];
  }

// Format an exectuable array for printing, redacting any user names in
// the path.
+ (NSString *) formatExecutable: (NSArray *) parts
  {
  NSMutableArray * mutableParts = [NSMutableArray arrayWithArray: parts];
  
  // Sanitize the executable.
  NSString * program = [mutableParts firstObject];
  
  if(program)
    [mutableParts insertObject: [Utilities cleanPath: program] atIndex: 0];
  
  return [mutableParts componentsJoinedByString: @" "];
  }

// Make a file name more presentable.
+ (NSString *) sanitizeFilename: (NSString *) file
  {
  NSString * prettyFile = file;
  
  // What are you trying to hide?
  if([file hasPrefix: @"."])
    prettyFile =
      [NSString
        stringWithFormat: NSLocalizedString(@"%@ (hidden)", NULL), file];

  // Silly Apple.
  else if([file hasPrefix: @"com.apple.CSConfigDotMacCert-"])
    prettyFile = [self sanitizeMobileMe: file];

  // What are you trying to expose?
  else if([file hasPrefix: @"com.facebook.videochat."])
    prettyFile = [self sanitizeFacebook: file];

  // What are you trying to expose?
  else if([file hasPrefix: @"com.adobe.ARM."])
    prettyFile = @"com.adobe.ARM.[...].plist";

  // I don't want to see it.
  else if([file length] > 76)
    {
    NSString * extension = [file pathExtension];
    
    prettyFile =
      [NSString
        stringWithFormat:
          @"%@...%@", [file substringToIndex: 40], extension];
    }
    
  return prettyFile;
  }

// Apple used to put the user's name into a file name.
+ (NSString *) sanitizeMobileMe: (NSString *) file
  {
  NSScanner * scanner = [NSScanner scannerWithString: file];

  bool found =
    [scanner
      scanString: @"com.apple.CSConfigDotMacCert-" intoString: NULL];

  if(!found)
    return file;
    
  found = [scanner scanUpToString: @"@" intoString: NULL];

  if(!found)
    return file;
    
  NSString * domain = nil;
  
  found = [scanner scanUpToString: @".com-" intoString: & domain];

  if(!found)
    return file;

  found = [scanner scanString: @".com-" intoString: NULL];

  if(!found)
    return file;
    
  NSString * suffix = nil;

  found = [scanner scanUpToString: @"\n" intoString: & suffix];

  if(!found)
    return file;
    
  return
    [NSString
      stringWithFormat:
        @"com.apple.CSConfigDotMacCert-[...]%@.com-%@", domain, suffix];
  }

/* Facebook puts the users name in a filename too. */
+ (NSString *) sanitizeFacebook: (NSString *) file
  {
  NSScanner * scanner = [NSScanner scannerWithString: file];

  bool found =
    [scanner
      scanString: @"com.facebook.videochat." intoString: NULL];

  if(!found)
    return file;
    
  [scanner scanUpToString: @".plist" intoString: NULL];

  return
    NSLocalizedString(@"com.facebook.videochat.[redacted].plist", NULL);
  }

@end
