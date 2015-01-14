/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect hardware information.
@interface HardwareCollector : Collector
  {
  NSDictionary * myProperties;
  NSImage * myMachineIcon;
  NSDictionary * myMachineImageLookup;
  NSString * myMarketingName;
  NSString * myEnglishMarketingName;
  }

// Machine properties.
@property (retain) NSDictionary * properties;

// The machine icon.
@property (retain) NSImage * machineIcon;

// The Apple Marketing name.
@property (retain) NSString * marketingName;

// English version of Apple Marketing name for the technical specifications
// fallback.
@property (retain) NSString * EnglishMarketingName;

// Find a machine icon.
- (NSImage *) findMachineIcon: (NSString *) code;

@end
