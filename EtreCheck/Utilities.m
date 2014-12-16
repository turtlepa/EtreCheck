/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Utilities.h"
#import "Model.h"

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
    [NSColor
      colorWithCalibratedRed: 0.2f green: 0.5f blue: 0.2f alpha: 0.0f];
    
  myBlue =
    [NSColor
      colorWithCalibratedRed: 0.0f green: 0.0f blue: 0.6f alpha: 0.0f];

  myGray =
    [NSColor
      colorWithCalibratedRed: 0.4f green: 0.4f blue: 0.4f alpha: 0.0f];

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
  return [self execute: program arguments: args error: NULL];
  }

// Execute an external program and return the results.
+ (NSData *) execute: (NSString *) program
  arguments: (NSArray *) args error: (NSString **) error
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
  
  NSData * result = nil;  
  NSData * errorData = nil;

  @try
    {
    [task launch];
    
    result =
      [[[task standardOutput] fileHandleForReading] readDataToEndOfFile];
    
    errorData =
      [[[task standardError] fileHandleForReading] readDataToEndOfFile];

    [task release];
    [errorPipe release];
    [outputPipe release];
    }
  @catch(NSException * exception)
    {
    if(error)
      *error = [exception description];
    }
  @catch(...)
    {
    if(error)
      *error = @"Unknown exception";
    }
    
  if(![result length] && error && [errorData length])
    *error =
      [[[NSString alloc]
        initWithData: errorData encoding: NSUTF8StringEncoding]
        autorelease];
    
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
  NSString * fullname = NSFullUserName();
  
  if(![username length])
    return path;
    
  NSRange range = [path rangeOfString: username];
  
  if(range.location == NSNotFound)
    {
    if([fullname length])
      range = [path rangeOfString: username];
    else
      return path;
    }
    
  // Now check for a hostname version.
  if(range.location == NSNotFound)
    {
    // See if the full user name is in the computer name.
    NSString * computerName = [[Model model] computerName];
    
    if(!computerName)
      return path;
      
    BOOL redact = NO;
    
    if([computerName rangeOfString: username].location != NSNotFound)
      redact = YES;
    else if([fullname length])
      if([computerName rangeOfString: fullname].location != NSNotFound)
        redact = YES;
      
    if(redact)
      {
      range = [path rangeOfString: computerName];

      if(range.location == NSNotFound)
        {
        NSString * hostName = [[Model model] hostName];
        
        if(hostName)
          range = [path rangeOfString: hostName];
        else
          range.location = NSNotFound;
        }
      }
    }
    
  if(range.location == NSNotFound)
    return path;
    
  return
    [NSString
      stringWithFormat:
        @"%@%@%@",
        [path substringToIndex: range.location],
        NSLocalizedString(@"[redacted]", NULL),
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
  NSString * prettyFile = [self cleanPath: file];
  
  // What are you trying to hide?
  if([file hasPrefix: @"."])
    prettyFile =
      [NSString
        stringWithFormat: NSLocalizedString(@"%@ (hidden)", NULL), file];

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

// Uncompress some data.
+ (NSData *) ungzip: (NSData *) gzipData
  {
  // Create pipes for handling communication.
  NSPipe * inputPipe = [NSPipe new];
  NSPipe * outputPipe = [NSPipe new];
  
  // Create the task itself.
  NSTask * task = [NSTask new];
  
  // Send all task output to the pipe.
  [task setStandardInput: inputPipe];
  [task setStandardOutput: outputPipe];
  
  [task setLaunchPath: @"/usr/bin/gunzip"];

  [task setCurrentDirectoryPath: @"/"];
  
  NSData * result = nil;
  
  @try
    {
    [task launch];
    
    dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
      ^{
        [[[task standardInput] fileHandleForWriting] writeData: gzipData];
        [[[task standardInput] fileHandleForWriting] closeFile];
      });
    
    result =
      [[[task standardOutput] fileHandleForReading] readDataToEndOfFile];
    
    [task release];
    [outputPipe release];
    }
  @catch(NSException * exception)
    {
    }
  @catch(...)
    {
    }
    
  return result;
  }

@end
