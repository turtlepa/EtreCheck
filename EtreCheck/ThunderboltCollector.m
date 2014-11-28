/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "ThunderboltCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"

// Collect information about Thunderbolt devices.
@implementation ThunderboltCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"thunderbolt";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking Thunderbolt information", NULL)];

  NSArray * args =
    @[
      @"-xml",
      @"SPThunderboltDataType"
    ];
  
  NSData * result =
    [Utilities execute: @"/usr/sbin/system_profiler" arguments: args];
  
  if(result)
    {
    NSArray * plist = [NSArray readPropertyListData: result];
  
    if(plist && [plist count])
      {
      BOOL found = NO;
      
      NSDictionary * devices =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      for(NSDictionary * device in devices)
        [self printThunderboltDevice: device indent: @"\t" found: & found];
        
      if(found)
        [self.result appendCR];
      }
    }
    
  dispatch_semaphore_signal(self.complete);
  }

// Collect information about a single Thunderbolt device.
- (void) printThunderboltDevice: (NSDictionary *) device
  indent: (NSString *) indent found: (BOOL *) found
  {
  NSString * name = [device objectForKey: @"_name"];
  NSString * vendor_name = [device objectForKey: @"vendor_name_key"];
        
  if(vendor_name)
    {
    if(!*found)
      {
      [self.result appendAttributedString: [self buildTitle]];
      
      *found = YES;
      }

    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"%@%@ %@\n", indent, vendor_name, name]];
            
    indent = [NSString stringWithFormat: @"%@\t", indent];
    }
  
  [self collectSMARTStatus: device indent: indent];
  
  // There could be more devices.
  [self printMoreDevices: device indent: indent found: found];
  }

// Print more devices.
- (void) printMoreDevices: (NSDictionary *) device
  indent: (NSString *) indent found: (BOOL *) found
  {
  NSDictionary * devices = [device objectForKey: @"_items"];
  
  if(!devices)
    devices = [device objectForKey: @"units"];
    
  if(devices)
    for(NSDictionary * device in devices)
      [self printThunderboltDevice: device indent: indent found: found];

  // Print all volumes on the device.
  [self printDiskVolumes: device];
  }

@end
