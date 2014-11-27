/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "GatekeeperCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"

// Gatekeeper settings.
typedef enum
  {
  kUnknown,
  kDisabled,
  kDeveloperID,
  kMacAppStore
  }
GatekeeperSetting;
    
// Collect Gatekeeper status.
@implementation GatekeeperCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"gatekeeper";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking Gatekeeper information", NULL)];

  // Only check gatekeeper on Maountain Lion or later.
  if([[Model model] majorOSVersion] < kMountainLion)
    return;
    
  [self.result appendAttributedString: [self buildTitle]];

  BOOL gatekeeperExists =
    [[NSFileManager defaultManager] fileExistsAtPath: @"/usr/sbin/spctl"];
  
  if(!gatekeeperExists)
    {
    [self.result
      appendString:
        NSLocalizedString(@"gatekeeperneedslion", NULL)
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];
    
    return;
    }

  GatekeeperSetting setting = [self collectGatekeeperSetting];
  
  [self printGatekeeperSetting: setting];

  [self.result appendCR];
    
  dispatch_semaphore_signal(self.complete);
  }

// Collect the Gatekeeper setting.
- (GatekeeperSetting) collectGatekeeperSetting
  {
  NSArray * args =
    @[
      @"--status",
      @"--verbose"
    ];
  
  NSData * data = [Utilities execute: @"/usr/sbin/spctl" arguments: args];

  NSArray * lines = [Utilities formatLines: data];

  GatekeeperSetting setting = kUnknown;
  
  for(NSString * line in lines)
    {
    NSString * trimmedLine =
      [line
        stringByTrimmingCharactersInSet:
          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
          
    if([trimmedLine isEqualToString: @""])
      continue;

    if([trimmedLine isEqualToString: @"assessments disabled"])
      setting = kDisabled;
    else if([trimmedLine isEqualToString: @"developer id enabled"])
      setting = kDeveloperID;
    else if([trimmedLine isEqualToString: @"developer id disabled"])
      setting = kMacAppStore;
    }
    
  // Perhaps I am on Mountain Lion and need to check the old debug
  // command line argument.
  if(setting == kUnknown)
    setting = [self collectMountainLionGatekeeperSetting];
      
  return setting;
  }

// Collect the Mountain Lion Gatekeeper setting.
- (GatekeeperSetting) collectMountainLionGatekeeperSetting
  {
  GatekeeperSetting setting = kUnknown;
  
  NSData * data =
    [Utilities
      execute: @"/usr/sbin/spctl" arguments: @[@"--test-devid-status"]];

  NSArray * lines = [Utilities formatLines: data];

  for(NSString * line in lines)
    {
    NSString * trimmedLine =
      [line
        stringByTrimmingCharactersInSet:
          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
          
    if([trimmedLine isEqualToString: @""])
      continue;

    if([trimmedLine isEqualToString: @"devid enabled"])
      setting = kDeveloperID;
    else if([trimmedLine isEqualToString: @"devid disabled"])
      setting = kMacAppStore;
    }
    
  return setting;
  }

// Print the Gatekeeper setting.
- (void) printGatekeeperSetting: (GatekeeperSetting) setting
  {
  switch(setting)
    {
    case kMacAppStore:
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"\t%@\n", NSLocalizedString(@"Mac App Store", NULL)]];
      break;
    case kDeveloperID:
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"\t%@\n",
              NSLocalizedString(
                @"Mac App Store and identified developers", NULL)]];
      break;
    case kDisabled:
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"\t%@\n", NSLocalizedString(@"Anywhere", NULL)]
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];
      break;
      
    case kUnknown:
    default:
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"\t%@\n", NSLocalizedString(@"Unknown!", NULL)]
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];
      break;
    }
  }

@end
