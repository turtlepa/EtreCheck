/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "USBCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"

// Collect information about USB devices.
@implementation USBCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"usb";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);

    self.progressEstimate = 1.2;
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Checking USB information", NULL)];

  NSArray * args =
    @[
      @"-xml",
      @"SPUSBDataType"
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
        [self printUSBDevice: device indent: @"\t" found: & found];

      if(found)
        [self.result appendCR];
      }
    }
  else
    [self.result appendCR];
    
  dispatch_semaphore_signal(self.complete);
  }

// Print a single USB device.
- (void) printUSBDevice: (NSDictionary *) device
  indent: (NSString *) indent found: (BOOL *) found
  {
  NSString * name = [device objectForKey: @"_name"];
  NSString * manufacturer = [device objectForKey: @"manufacturer"];
  NSString * size = [device objectForKey: @"size"];

  if(!manufacturer)
    manufacturer = [device objectForKey: @"f_manufacturer"];

  if(!size)
    size = @"";
    
  if(manufacturer)
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
            @"%@%@ %@ %@\n", indent, manufacturer, name, size]];
            
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
      [self printUSBDevice: device indent: indent found: found];

  // Print all volumes on the device.
  [self printDiskVolumes: device];
  }

@end
