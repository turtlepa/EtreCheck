/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect information about disks.
@interface DiskCollector : Collector

// Provide easy access to volumes.
@property (readonly) NSMutableDictionary * volumes;

// Provide easy access to Core Storage volumes.
@property (readonly) NSMutableDictionary * coreStorageVolumes;

// Get the SMART status for this disk.
- (void) collectSMARTStatus: (NSDictionary *) disk
  indent: (NSString *) indent;

// Print the volumes on a disk.
- (void) printDiskVolumes: (NSDictionary *) disk;

@end
