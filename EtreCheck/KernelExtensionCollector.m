//
/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "KernelExtensionCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "SystemInformation.h"

@implementation KernelExtensionCollector

@synthesize extensions = myExtensions;
@synthesize loadedExtensions = myLoadedExtensions;
@synthesize unloadedExtensions = myUnloadedExtensions;
@synthesize unexpectedExtensions = myUnexpectedExtensions;
@synthesize extensionsByLocation = myExtensionsByLocation;

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    myExtensionsByLocation = [NSMutableDictionary new];
    
    self.progressEstimate = 28.0;
    self.name = @"kernelextensions";
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  self.unexpectedExtensions = nil;
  self.unloadedExtensions = nil;
  self.loadedExtensions = nil;
  self.extensions = nil;
  [myExtensionsByLocation release];
  
  [super dealloc];
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Checking kernel extensions", NULL)];

  // Collect all types of extensions.
  [self collectAllExtensions];
    
  // Divvy the extensions up into loaded, unloaded, and unexpected.
  [self categorizeExtensions];
    
  // Format all extensions into an array to be printed.
  NSArray * formattedOutput = [self formatExtensions];
  
  // Now print the output.
  if([formattedOutput count])
    {
    [self.result
      appendAttributedString: [self buildTitle: @"Kernel Extensions:"]];
    
    for(NSAttributedString * output in formattedOutput)
      {
      [self.result appendAttributedString: output];
      [self.result appendString: @"\n"];
      }
    }

  [self
    setTabs: @[@28, @112]
    forRange: NSMakeRange(0, [self.result length])];
  }

// Collect all extensions on the system.
- (void) collectAllExtensions
  {
  NSMutableDictionary * allExtensions = [NSMutableDictionary dictionary];
  
  [allExtensions addEntriesFromDictionary: [self collectExtensions]];
  [allExtensions addEntriesFromDictionary: [self collectSystemExtensions]];
  [allExtensions
    addEntriesFromDictionary: [self collectApplicationSupportExtensions]];
  [allExtensions
    addEntriesFromDictionary:
      [self collectSystemApplicationSupportExtensions]];
  [allExtensions
    addEntriesFromDictionary: [self collectStartupItemExtensions]];
  [allExtensions
    addEntriesFromDictionary: [self collectApplicationExtensions]];
  
  self.extensions = allExtensions;
  }

// Collect 3rd party extensions.
- (NSDictionary *) collectExtensions
  {
  NSArray * args =
    @[
      @"/Library/Extensions",
      @"-iname",
      @"*.kext"];
  
  NSData * data = [Utilities execute: @"/usr/bin/find" arguments: args];

  return [self parseBundles: data];
  }

// Collect system extensions.
- (NSDictionary *) collectSystemExtensions
  {
  NSArray * args =
    @[
      @"/System/Library/Extensions",
      @"-iname",
      @"*.kext"];
  
  NSData * data = [Utilities execute: @"/usr/bin/find" arguments: args];

  return [self parseBundles: data];
  }

// Collect application support extensions.
- (NSDictionary *) collectApplicationSupportExtensions
  {
  NSArray * args =
    @[
      @"/Library/Application Support",
      @"-iname",
      @"*.kext"];
  
  NSData * data = [Utilities execute: @"/usr/bin/find" arguments: args];

  return [self parseBundles: data];
  }

// Collect system application support extensions.
- (NSDictionary *) collectSystemApplicationSupportExtensions
  {
  NSArray * args =
    @[
      @"/System/Library/Application Support",
      @"-iname",
      @"*.kext"];
  
  NSData * data = [Utilities execute: @"/usr/bin/find" arguments: args];

  return [self parseBundles: data];
  }

// Collect startup item extensions.
- (NSDictionary *) collectStartupItemExtensions
  {
  NSArray * args =
    @[
      @"/Library/StartupItems",
      @"-iname",
      @"*.kext"];
  
  NSData * data = [Utilities execute: @"/usr/bin/find" arguments: args];
  
  return [self parseBundles: data];
  }

// Collect application extensions.
- (NSDictionary *) collectApplicationExtensions
  {
  NSMutableDictionary * extensions = [NSMutableDictionary dictionary];
  
  NSDictionary * applications =
    [[SystemInformation sharedInformation] applications];
  
  for(NSString * name in applications)
    {
    NSDictionary * application = [applications objectForKey: name];
    
    [extensions
      addEntriesFromDictionary: [self collectExtensionsIn: application]];
    }
    
  return extensions;
  }

// Collect extensions from a specific application.
- (NSDictionary *) collectExtensionsIn: (NSDictionary *) application
  {
  NSString * bundleID = [application objectForKey: @"CFBundleIdentifier"];

  if(bundleID)
    {
    if([bundleID hasPrefix: @"com.apple."])
      return @{};
        
    NSArray * args =
      @[
        [application objectForKey: @"path"],
        @"-iname",
        @"*.kext"];
    
    NSData * data = [Utilities execute: @"/usr/bin/find" arguments: args];
    
    return [self parseBundles: data];
    }
    
  return @{};
  }

// Return a dictionary of expanded bundle dictionaries found in a directory.
- (NSDictionary *) parseBundles: (NSData *) data
  {
  NSArray * lines = [Utilities formatLines: data];
  
  NSMutableDictionary * bundles = [NSMutableDictionary dictionary];

  for(NSString * line in lines)
    {
    NSString * versionPlist =
      [line stringByAppendingPathComponent: @"Contents/Info.plist"];

    NSDictionary * plist = [Utilities readPropertyList: versionPlist];

    if(plist)
      {
      NSString * identifier = [plist objectForKey: @"CFBundleIdentifier"];
      
      if(identifier)
        {
        NSDictionary * bundle =
          [NSMutableDictionary dictionaryWithDictionary: plist];
        
        // Save the path too.
        [bundle setValue: [self extensionDirectory: line] forKey: @"path"];
        
        [bundles setObject: bundle forKey: identifier];
        }
      }
    }
    
  return bundles;
  }

// Get the path from a bundle and type.
- (NSString *) extensionDirectory: (NSString *) path
  {
  NSArray * parts = [path componentsSeparatedByString: @"/"];

  NSMutableArray * pathParts = [NSMutableArray array];
  
  for(NSString * part in parts)
    {
    [pathParts addObject: part];
    
    if([[part pathExtension] isEqualToString: @"app"])
      return [pathParts componentsJoinedByString: @"/"];
    }
    
  return [path stringByDeletingLastPathComponent];
  }

// Return the next component after a prefix in a path.
- (NSString *) pathWithPrefix: (NSString *) prefix path: (NSString *) path
  {
  NSString * relativePath = [path substringFromIndex: [prefix length]];
  
  NSArray * parts = [relativePath componentsSeparatedByString: @"/"];
  
  return [parts firstObject];
  }

// Categories the extensions into various types.
- (void) categorizeExtensions
  {
  // Find loaded (and unexpecteded loaded) extensions.
  [self findLoadedExtensions];
  
  // The rest must be unloaded.
  [self findUnloadedExtensions];

  // Now organize by path.
  for(NSString * label in self.extensions)
    {
    NSDictionary * bundle = [self.extensions objectForKey: label];
    
    NSString * path = [bundle objectForKey: @"path"];
      
    NSMutableArray * extensions =
      [self.extensionsByLocation objectForKey: path];
      
    if(!extensions)
      {
      extensions = [NSMutableArray array];
      
      [self.extensionsByLocation setObject: extensions forKey: path];
      }
      
    [extensions addObject: label];
    }
  }

// Find loaded extensions.
- (void) findLoadedExtensions
  {
  NSArray * args = @[ @"-l" ];
  
  NSData * result =
    [Utilities execute: @"/usr/sbin/kextstat" arguments: args];
  
  NSArray * lines = [Utilities formatLines: result];

  self.loadedExtensions = [NSMutableDictionary dictionary];
  self.unexpectedExtensions = [NSMutableDictionary dictionary];
  
  for(NSString * line in lines)
    {
    NSString * label = nil;
    NSString * version = nil;

    [self parseKext: line label: & label version: & version];

    if(label && version)
      {
      NSDictionary * bundle = [self.extensions objectForKey: label];
      
      if(bundle)
        [self.loadedExtensions setObject: bundle forKey: label];
        
      else
        {
        bundle =
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              version, @"CFBundleVersion",
              label, @"CFBundleIdentifier",
              nil];
          
        [self.unexpectedExtensions setObject: bundle forKey: label];
        }
      }
    }
  }

// Find unloaded extensions.
- (void) findUnloadedExtensions
  {
  self.unloadedExtensions = [NSMutableDictionary dictionary];

  // The rest must be unloaded.
  for(NSString * label in self.extensions)
    {
    NSDictionary * loadedBundle =
      [self.loadedExtensions objectForKey: label];
    
    if(!loadedBundle)
      [self.unloadedExtensions
        setObject: [self.extensions objectForKey: label] forKey: label];
    }
  }

// Parse a single line of kextctl output.
- (void) parseKext: (NSString *) line
  label: (NSString **) label version: (NSString **) version
  {
  NSScanner * scanner = [NSScanner scannerWithString: line];

  for(int i = 0; i < 5; ++i)
    if(![scanner scanUpToString: @" " intoString: NULL])
      return;

  BOOL found = [scanner scanUpToString: @" (" intoString: label];

  if(!found)
    return;

  [scanner scanString: @"(" intoString: NULL];
  [scanner scanUpToString: @")" intoString: version];
  }

// Should an extension be ignored if unloaded?
- (BOOL) ignoreUnloadedExtension: (NSString *) label
  {
  if([label hasPrefix: @"com.huawei.driver."])
    return YES;
  else if([label hasPrefix: @"com.hp."])
    return YES;
  else if([label hasPrefix: @"com.epson."])
    return YES;
  else if([label hasPrefix: @"com.lexmark."])
    return YES;
  else if([label hasPrefix: @"jp.co.canon."])
    return YES;
  else if([label hasPrefix: @"com.Areca.ArcMSR"])
    return YES;
  else if([label hasPrefix: @"com.ATTO.driver.ATTO"])
    return YES;
  else if([label hasPrefix: @"com.Accusys.driver.Acxxx"])
    return YES;
  else if([label hasPrefix: @"com.jmicron.JMicronATA"])
    return YES;
  else if([label hasPrefix: @"com.softraid.driver.SoftRAID"])
    return YES;
  else if([label hasPrefix: @"com.promise.driver.stex"])
    return YES;
  else if([label hasPrefix: @"com.highpoint-tech.kext.HighPoint"])
    return YES;
  else if([label hasPrefix: @"com.CalDigit.driver.HDPro"])
    return YES;

  // Snow Leopard.
  else if([label hasPrefix: @"com.Immersion.driver.ImmersionForceFeedback"])
    return YES;
  else if([label hasPrefix: @"com.acard.driver.ACard6"])
    return YES;
  else if([label hasPrefix: @"com.logitech.driver.LogitechForceFeedback"])
    return YES;

  return NO;
  }

// Format non-standard extensions.
- (NSArray *) formatExtensions
  {
  NSMutableArray * extensions = [NSMutableArray array];
    
  NSArray * sortedDirectories =
    [[self.extensionsByLocation allKeys]
      sortedArrayUsingSelector: @selector(compare:)];

  for(NSString * directory in sortedDirectories)
    [extensions
      addObjectsFromArray: [self formatExtensionDirectory: directory]];
    
  return extensions;
  }

// Format a directory of extensions.
- (NSArray *) formatExtensionDirectory: (NSString *) directory
  {
  NSMutableArray * extensions = [NSMutableArray array];
  
  NSArray * sortedExtensions =
    [[self.extensionsByLocation objectForKey: directory]
      sortedArrayUsingSelector: @selector(compare:)];

  for(NSString * label in sortedExtensions)
    {
    NSAttributedString * output = [self formatExtension: label];
    
    // Outpt could be nil if this is an Apple extension.
    if(output)
      [extensions addObject: output];
    }
    
  // If I found any non-nil extensions, insert a header for the directory.
  if([extensions count])
    {
    NSMutableAttributedString * string =
      [[NSMutableAttributedString alloc] initWithString: @""];
    
    // This will add a new line at the end.
    [extensions addObject: [[string copy] autorelease]];
    
    [string
      appendString:
        [NSString
          stringWithFormat: @"\t\t%@", [Utilities cleanPath: directory]]
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
        }];
    
    [extensions insertObject: string atIndex: 0];
      
    [string release];
    }
    
  return extensions;
  }

// Format an extension for output.
- (NSAttributedString *) formatExtension: (NSString *) label
  {
  if([label hasPrefix: @"com.apple."])
    return nil;

  NSColor * color = [[Utilities shared] blue];

  NSString * status = NSLocalizedString(@"[loaded]", NULL);
  
  if([self.unloadedExtensions objectForKey: label])
    {
    status = NSLocalizedString(@"[not loaded]", NULL);
    color = [[Utilities shared] gray];

    if([self ignoreUnloadedExtension: label])
      return nil;
    }
    
  return [self formatBundle: label status: status color: color];
  }

// Return a formatted bundle.
- (NSAttributedString *) formatBundle: (NSString * ) label
  status: (NSString *) status color: (NSColor *) color
  {
  NSMutableAttributedString * formattedOutput =
    [[NSMutableAttributedString alloc] init];
    
  NSDictionary * bundle = [self.extensions objectForKey: label];
  
  NSString * version = [bundle objectForKey: @"CFBundleVersion"];

  int age = 0;
  
  NSString * OSVersion = [self getOSVersion: bundle age: & age];
    
  [formattedOutput
    appendString:
      [NSString
        stringWithFormat:
          @"\t%@\t", status]
    attributes:
      [NSDictionary
        dictionaryWithObjectsAndKeys:
          color, NSForegroundColorAttributeName, nil]];

  [formattedOutput
    appendString:
      [NSString
        stringWithFormat: @"%@ (%@%@)", label, version, OSVersion]];
    
  [formattedOutput
    appendAttributedString: [self getSupportLink: bundle]];
    
  return [formattedOutput autorelease];
  }

@end
