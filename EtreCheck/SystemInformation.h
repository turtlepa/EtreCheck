/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// Major OS versions.
#define kSnowLeopard  10
#define kLion         11
#define kMountainLion 12
#define kMavericks    13
#define kYosemite     14

// A singleton to keep track of system information.
@interface SystemInformation : NSObject
  {
  int myMajorOSVersion;
  NSMutableDictionary * myVolumes;
  NSDictionary * myApplications;
  int myPhysicalRAM;
  NSImage * myMachineIcon;
  NSDictionary * myProcesses;
  }

// Keep track of the OS version.
@property (assign) int majorOSVersion;

// Keep track of system volumes.
@property (retain) NSMutableDictionary * volumes;

// Keep track of applications.
@property (retain) NSDictionary * applications;

// I will need the RAM amount (in GB) for later.
@property (assign) int physicalRAM;

// See if I can get the machine image.
@property (retain) NSImage * machineIcon;

// All processes.
@property (retain) NSDictionary * processes;

// Return the singeton of shared values.
+ (SystemInformation *) sharedInformation;

@end
