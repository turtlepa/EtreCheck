/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect information about disks.
@interface DiskCollector : Collector
  {
  NSMutableDictionary * myCoreStorageVolumes;
  }

// Provide easy access to volumes.
@property (readonly) NSMutableDictionary * volumes;

// Provide easy access to CoreStorage volumes.
@property (readonly) NSMutableDictionary * coreStorageVolumes;

// Get the SMART status for this disk.
- (void) collectSMARTStatus: (NSDictionary *) disk
  indent: (NSString *) indent;

// Print information about a volume.
- (void) printVolume: (NSDictionary *) volume indent: (NSString *) indent;

@end
