/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "PlugInsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "SystemInformation.h"
#import "Utilities.h"
#import "NSDictionary+Etresoft.h"

// Base class that knows how to handle plug-ins of various types.
@implementation PlugInsCollector

// Parse plugins
- (void) parsePlugins: (NSString *) type path: (NSString *) path
  {
  // Find all the plug-in bundles in the given path.
  NSDictionary * bundles = [self parseFiles: path];
  
  if([bundles count])
    {
    [self.result appendAttributedString: [self buildTitle: type]];

    for(NSString * filename in bundles)
      {
      NSDictionary * plugin = [bundles objectForKey: filename];

      NSString * name = [filename stringByDeletingPathExtension];

      NSString * version =
        [plugin objectForKey: @"CFBundleShortVersionString"];

      int age = 0;
      
      NSString * OSVersion = [self getOSVersion: plugin age: & age];
      
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              NSLocalizedString(@"\t%@: Version: %@%@", NULL),
              name, version, OSVersion]];
 
      // Some plug-ins are special.
      if([name isEqualToString: @"JavaAppletPlugin"])
        [self.result
          appendAttributedString: [self getJavaSupportLink: plugin]];
      else if([name isEqualToString: @"Flash Player"])
        [self.result
          appendAttributedString: [self getFlashSupportLink: plugin]];
      else
        [self.result
          appendAttributedString: [self getSupportLink: plugin]];
      
      [self.result appendString: @"\n"];
      }

    [self.result appendString: @"\n"];
    }
  }

// Find all the plug-in bundles in the given path.
- (NSDictionary *) parseFiles: (NSString *) path
  {
  NSArray * args = @[ path, @"-iname", @"*.plugin" ];
  
  NSData * data = [Utilities execute: @"/usr/bin/find" arguments: args];
  
  NSArray * paths = [Utilities formatLines: data];
  
  NSMutableDictionary * bundles = [NSMutableDictionary dictionary];

  for(NSString * path in paths)
    {
    NSString * filename = [path lastPathComponent];

    NSString * versionPlist =
      [path stringByAppendingPathComponent: @"Contents/Info.plist"];

    NSDictionary * plist = [NSDictionary readPropertyList: versionPlist];

    if(!plist)
      plist =
        @{ @"CFBundleShortVersionString" : @"Unknown" };

    [bundles setObject: plist forKey: filename];
    }
    
  return bundles;
  }

// Construct a Java support link.
- (NSAttributedString *) getJavaSupportLink: (NSDictionary *) plugin
  {
  NSMutableAttributedString * string =
    [[NSMutableAttributedString alloc] initWithString: @""];

  NSString * url =
    NSLocalizedString(
      @"http://www.java.com/en/download/installed.jsp", NULL);
  
  if([[SystemInformation sharedInformation] majorOSVersion] < 11)
    url = NSLocalizedString(@"http://support.apple.com/kb/dl1572", NULL);

  [string appendString: @" "];

  [string
    appendString: NSLocalizedString(@"Check version", NULL)
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] gray],
        NSLinkAttributeName : url
      }];
   
  return [string autorelease];
  }

// Construct a Flash support link.
- (NSAttributedString *) getFlashSupportLink: (NSDictionary *) plugin
  {
  NSString * version =
    [plugin objectForKey: @"CFBundleShortVersionString"];

  NSString * currentVersion = [self currentFlashVersion];
  
  if(!currentVersion)
    return
      [[[NSMutableAttributedString alloc]
        initWithString: NSLocalizedString(@" Cannot contact Adobe", NULL)
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]]
        autorelease];
    
  if([version isEqualToString: currentVersion])
    return [self getSupportLink: plugin];
    
  NSString * maxVersion = [self maxVersion: @[version, currentVersion]];
  
  if([maxVersion isEqualToString: currentVersion])
    return [self outdatedFlash];
    
  return [self mismatchedFlash: currentVersion];
  }

// Get the current Flash version.
- (NSString *) currentFlashVersion
  {
  NSString * version = nil;
  
  NSURL * url =
    [NSURL URLWithString: @"http://www.adobe.com/software/flash/about/"];
  
  NSData * data = [NSData dataWithContentsOfURL: url];
  
  if(data)
    {
    NSString * content =
      [[NSString alloc]
        initWithData: data encoding:NSUTF8StringEncoding];
    
    NSScanner * scanner = [NSScanner scannerWithString: content];
  
    [scanner scanUpToString: @"Macintosh" intoString: NULL];
    [scanner scanUpToString: @"<td>" intoString: NULL];
    [scanner scanString: @"<td>" intoString: NULL];
    [scanner scanUpToString: @"<td>" intoString: NULL];
    [scanner scanString: @"<td>" intoString: NULL];

    NSString * currentVersion = nil;
    
    BOOL scanned =
      [scanner scanUpToString: @"</td>" intoString: & currentVersion];
    
    if(scanned)
      version = currentVersion;
      
    [content release];
    }
    
  return version;
  }

// Return an outdated Flash version.
- (NSAttributedString *) outdatedFlash
  {
  NSMutableAttributedString * string =
    [[NSMutableAttributedString alloc] initWithString: @""];
  
  NSAttributedString * outdated =
    [[NSAttributedString alloc]
      initWithString: NSLocalizedString(@"Outdated!", NULL)
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];

  [string appendString: @" "];
  [string appendAttributedString: outdated];
  [string appendString: @" "];
  
  [string
    appendString: NSLocalizedString(@"Update", NULL)
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] red],
        NSLinkAttributeName : @"http://get.adobe.com/flashplayer/"
      }];
  
  [outdated release];
  
  return [string autorelease];
  }

// Return a mismatched Flash version.
- (NSAttributedString *) mismatchedFlash: (NSString *) currentVersion
  {
  NSMutableAttributedString * string =
    [[NSMutableAttributedString alloc] initWithString: @""];
  
  NSAttributedString * outdated =
    [[NSAttributedString alloc]
      initWithString: NSLocalizedString(@"Mismatch!", NULL)
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];

  [string appendString: @" "];
  [string appendAttributedString: outdated];
  [string appendString: @" "];

  [string
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(@"Adobe recommends %@", NULL),
          currentVersion]
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] red],
        NSLinkAttributeName : @"http://get.adobe.com/flashplayer/"
      }];
   
  [outdated release];
  
  return [string autorelease];
  }

// Parse user plugins
- (void) parseUserPlugins: (NSString *) type path: (NSString *) path
  {
  [self
    parsePlugins: type
    path: [NSHomeDirectory() stringByAppendingPathComponent: path]];
  }

@end
