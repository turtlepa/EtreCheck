/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "StartupItemsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
#import "NSDictionary+Etresoft.h"

// Collect old startup items.
@implementation StartupItemsCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"startupitems";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking obsolete startup items", NULL)];

  // Get startup item bundles on disk.
  startupBundles = [self getStartupItemBundles];
  
  NSArray * args =
    @[
      @"-xml",
      @"SPStartupItemDataType"
    ];
  
  NSData * result =
    [Utilities execute: @"/usr/sbin/system_profiler" arguments: args];
  
  if(result)
    {
    NSArray * plist = [NSArray readPropertyListData: result];
  
    if(plist && [plist count])
      {
      NSArray * items = [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([items count])
        {
        [self.result appendAttributedString: [self buildTitle]];
        
        for(NSDictionary * item in items)
          [self printStartupItem: item];
          
        [self.result
          appendString: NSLocalizedString(@"startupitemsdeprecated", NULL)
          attributes:
            @{
              NSForegroundColorAttributeName : [[Utilities shared] red],
            }];

        [self.result appendCR];
        }
      }
    }
    
  dispatch_semaphore_signal(self.complete);
  }

// Get startup item bundles.
- (NSDictionary *) getStartupItemBundles
  {
  NSArray * args =
    @[
      @"/Library/StartupItems",
      @"-iname",
      @"Info.plist"];
  
  NSData * data = [Utilities execute: @"/usr/bin/find" arguments: args];

  NSArray * files = [Utilities formatLines: data];

  NSMutableDictionary * bundles = [NSMutableDictionary dictionary];

  for(NSString * file in files)
    {
    NSDictionary * plist = [NSDictionary readPropertyList: file];

    if(plist)
      [bundles setObject: plist forKey: file];
    }
    
  return bundles;
  }

// Print a startup item.
- (void) printStartupItem: (NSDictionary *) item
  {
  NSString * name = [item objectForKey: @"_name"];
  NSString * path = [item objectForKey: @"spstartupitem_location"];

  NSString * version = @"";
  
  for(NSString * infoPList in startupBundles)
    if([infoPList hasPrefix: path])
      {
      NSString * appVersion =
        [item objectForKey: @"CFBundleShortVersionString"];

      int age = 0;
      
      NSString * OSVersion = [self getOSVersion: item age: & age];
        
      if([appVersion length] || [OSVersion length])
        {
        NSMutableString * compositeVersion = [NSMutableString string];
        
        [compositeVersion
          appendFormat: @"(%@", [appVersion length] ? appVersion : @""];
        [compositeVersion
          appendFormat:
            @"%@%@)",
            ([appVersion length] && [OSVersion length])
              ? @" - "
              : @"",
            [OSVersion length] ? OSVersion : @""];
          
        version =
          [NSString
            stringWithFormat:
              NSLocalizedString(@"Version: %@", NULL), compositeVersion];
        }
      }
    
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(@"\t%@: %@Path: %@\n", NULL),
          name, version, path]
    attributes:
      @{
        NSForegroundColorAttributeName : [[Utilities shared] red],
      }];
  }

@end
