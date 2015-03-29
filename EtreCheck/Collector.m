/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"

@implementation Collector

@synthesize name = myName;
@synthesize title = myTitle;
@synthesize result = myResult;
@synthesize complete = myComplete;
@dynamic done;

// Is this collector complete?
- (bool) done
  {
  return !dispatch_semaphore_wait(self.complete, DISPATCH_TIME_NOW);
  }

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    myResult = [NSMutableAttributedString new];
    myFormatter = [NSNumberFormatter new];
    myComplete = dispatch_semaphore_create(0);
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  dispatch_release(myComplete);
  [myFormatter release];
  [myResult release];
  
  [super dealloc];
  }

// Perform the collection.
- (void) collect
  {
  // Derived classes must implement.
  }

// Update status.
- (void) updateStatus: (NSString *) status
  {
  [[NSNotificationCenter defaultCenter]
    postNotificationName: kStatusUpdate object: status];
  }

// Construct a title with a bold, blue font using a given anchor into
// the online help.
- (NSAttributedString *) buildTitle
  {
  NSMutableAttributedString * string = [NSMutableAttributedString new];
    
  NSString * title =
    [NSString
      stringWithFormat:
        @"%@ %@",
        NSLocalizedString(self.title, NULL),
        NSLocalizedString(@"info", NULL)];
    
  NSString * url =
    [NSString
      stringWithFormat:
        @"http://www.etresoft.com/etrecheck_story#%@", self.name];
  
  url = [NSString stringWithFormat: @"etrecheck://help/%@", self.name];

  [string
    appendString: title
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSLinkAttributeName : url
      }];
    
  [string appendString: @"\n"];
  
  return [string autorelease];
  }

// Set tabs in the result.
- (void) setTabs: (NSArray *) stops forRange: (NSRange) range
  {
  // Setup some tab stops to use.
  NSMutableArray * tabStops = [NSMutableArray array];
  
  for(NSNumber * stop in stops)
    {
    NSTextTab * tab =
      [[NSTextTab alloc]
        initWithType: NSLeftTabStopType location: [stop intValue]];
      
    [tabStops addObject: tab];

    [tab release];
    }

  // Setup some paragraph sytles.
  NSMutableParagraphStyle * paragraphStyle =
    [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
   
  [paragraphStyle setTabStops: tabStops];
      
  [self.result
    addAttribute: NSParagraphStyleAttributeName
    value: paragraphStyle
    range: range];

  [paragraphStyle release];
  }

// Convert a program name and optional bundle ID into a DNS-style URL.
- (NSAttributedString *) getSupportURL: (NSString *) name
  bundleID: (NSString *) path
  {
  NSMutableAttributedString * url =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  NSString * bundleID = [path lastPathComponent];
  
  if([bundleID hasPrefix: @"com.apple."])
    return [url autorelease];
    
  NSString * host = [self convertBundleIdToHost: bundleID];
  
  if(host)
    {
    NSString * nameParameter =
      [name length]
        ? [NSString stringWithFormat: @"%@+", name]
        : @"";

    NSString * query =
      [NSString
        stringWithFormat:
          @"http://www.google.com/search?q=%@support+site:%@",
          nameParameter, host];
    
    [url appendString: @" "];

    [url
      appendString: NSLocalizedString(@"[Click for support]", NULL)
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
          NSForegroundColorAttributeName : [[Utilities shared] blue],
          NSLinkAttributeName : query
        }];
    }
    
  return [url autorelease];
  }

// Get a support link from a bundle.
- (NSAttributedString *) getSupportLink: (NSDictionary *) bundle
  {
  NSString * name = [bundle objectForKey: @"CFBundleName"];
  NSString * bundleID = [bundle objectForKey: @"CFBundleIdentifier"];

  if(bundleID)
    {
    NSAttributedString * supportLink =
      [self getSupportURL: name bundleID: bundleID];
        
    if(supportLink)
      return supportLink;
    }
    
  return [[[NSAttributedString alloc] initWithString: @""] autorelease];
  }

// Extract the (possible) host from a bundle ID.
- (NSString *) convertBundleIdToHost: (NSString *) bundleID
  {
  NSScanner * scanner = [NSScanner scannerWithString: bundleID];
  
  NSString * domain = nil;
  
  if([scanner scanUpToString: @"." intoString: & domain])
    {
    [scanner scanString: @"." intoString: NULL];

    NSString * name = nil;
    
    if([scanner scanUpToString: @"." intoString: & name])
      return [NSString stringWithFormat: @"%@.%@", name, domain];
    }
  
  return nil;
  }

// Try to determine the OS version associated with a bundle.
- (NSString *) getOSVersion: (NSDictionary *) info age: (int *) age
  {
  NSString * version = [self getSDKVersion: info age: age];
  
  if(version)
    return version;
    
  version = [self getSDKName: info age: age];
  
  if(version)
    return version;
    
  version = [self getBuildVersion: info age: age];
  
  if(version)
    return version;
    
  return @"";
  }

// Return the build version of a bundle.
- (NSString *) getBuildVersion: (NSDictionary *) info age: (int *) age
  {
  NSString * buildVersion = [info objectForKey: @"BuildMachineOSBuild"];

  if(buildVersion)
    {
    NSScanner * scanner = [NSScanner scannerWithString: buildVersion];
    
    int majorVersion = 0;
    
    bool found = [scanner scanInt: & majorVersion];
    
    if(found)
      {
      if(age)
        *age =
          ([[Model model] majorOSVersion] -
            majorVersion);
        
      NSString * minorVersion = nil;
      
      found =
        [scanner
          scanCharactersFromSet:
            [NSCharacterSet
              characterSetWithCharactersInString:
                @"ABCDEFGHIKLMNOPQRSTUVWXYZ"]
              intoString: & minorVersion];
        
      if(found)
        return
          [NSString stringWithFormat: @" - OS X 10.%d", majorVersion - 4];
      }
    }
    
  return nil;
  }

// Return the SDKVersion of a bundle.
- (NSString *) getSDKVersion: (NSDictionary *) info age: (int *) age
  {
  NSString * sdkVersion = [info objectForKey: @"DTSDKBuild"];

  if(sdkVersion)
    {
    NSScanner * scanner = [NSScanner scannerWithString: sdkVersion];
    
    int majorVersion = 0;
    
    bool found = [scanner scanInt: & majorVersion];
    
    if(found)
      {
      if(age)
        *age =
          ([[Model model] majorOSVersion] -
            majorVersion);
        
      NSString * minorVersion = nil;
      
      found =
        [scanner
          scanCharactersFromSet:
            [NSCharacterSet
              characterSetWithCharactersInString:
                @"ABCDEFGHIKLMNOPQRSTUVWXYZ"]
              intoString:& minorVersion];
        
      if(found)
        return
          [NSString stringWithFormat: @" - SDK 10.%d", majorVersion - 4];
      }
    }
    
  return nil;
  }

// Return the SDK name of a bundle.
- (NSString *) getSDKName: (NSDictionary *) info age: (int *) age
  {
  NSString * sdkName = [info objectForKey: @"DTSDKName"];
  
  if(sdkName)
    {
    NSScanner * scanner = [NSScanner scannerWithString: sdkName];
    
    [scanner scanString: @"macosx10." intoString: NULL];
    
    int majorVersion = 0;
    
    bool found = [scanner scanInt: & majorVersion];
    
    if(found)
      {
      if(age)
        *age =
          ([[Model model] majorOSVersion] -
            majorVersion);
      
      return [NSString stringWithFormat: @" - SDK 10.%d", majorVersion - 4];
      }
    }
    
  return nil;
  }

// Find the maximum of two version number strings.
- (NSString *) maxVersion: (NSArray *) versions
  {
  if([versions count] < 2)
    return [versions lastObject];
  
  [myFormatter setNumberStyle: NSNumberFormatterNoStyle];
  
  NSString * version1 = [versions objectAtIndex: 0];
  NSString * version2 = [versions objectAtIndex: 1];
  
  NSCharacterSet * delimiters =
    [NSCharacterSet characterSetWithCharactersInString: @". "];
    
  NSArray * value1 =
    [version1 componentsSeparatedByCharactersInSet: delimiters];
  NSArray * value2 =
    [version2 componentsSeparatedByCharactersInSet: delimiters];
  
  NSUInteger index = 0;

  NSComparisonResult result = NSOrderedSame;
  
  while(result == NSOrderedSame)
    {
    if(index == [value2 count])
      break;
    
    if(index == [value1 count])
      {
      result = NSOrderedAscending;
      
      break;
      }
      
    result =
      [self
        compareValue: [value1 objectAtIndex: index]
        withValue: [value2 objectAtIndex: index]
        formatter: myFormatter];
      
    ++index;
    }
  
  return
    result == NSOrderedAscending
      ? version2
      : version1;
  }

// Compare two values, formatted as numbers, if possible.
- (NSComparisonResult) compareValue: (NSString *) value1
  withValue: (NSString *) value2 formatter: (NSNumberFormatter *) formatter
  {
  NSNumber * numberValue1 = [formatter numberFromString: value1];
  NSNumber * numberValue2 = [formatter numberFromString: value2];

  if(numberValue1 && numberValue2)
    return [numberValue1 compare: numberValue1];
    
  return [value1 compare: value2];
  }

// Generate a "remove adware" link.
- (NSAttributedString *) generateRemoveAdwareLink: (NSString *) name
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  NSString * url =
    [NSString
      stringWithFormat: @"etrecheck://adware/%@", [name lowercaseString]];
  
  [urlString
    appendString: NSLocalizedString(@" [", NULL)
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] red]
      }];

  [urlString
    appendString: NSLocalizedString(@"Adware!", NULL)
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] red]
      }];

  [urlString
    appendString: NSLocalizedString(@"] - [", NULL)
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] red]
      }];

  [urlString
    appendString: NSLocalizedString(@"Remove", NULL)
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] red],
        NSLinkAttributeName : url
      }];
    
  [urlString
    appendString: NSLocalizedString(@"]", NULL)
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] red]
      }];

  return [urlString autorelease];
  }

@end
