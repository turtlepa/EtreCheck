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

@class DiagnosticEvent;

// A singleton to keep track of system information.
@interface Model : NSObject
  {
  int myMajorOSVersion;
  NSMutableDictionary * myVolumes;
  NSMutableDictionary * myCoreStorageVolumes;
  NSMutableDictionary * myDiskErrors;
  NSArray * myLogEntries;
  NSDictionary * myApplications;
  int myPhysicalRAM;
  NSImage * myMachineIcon;
  NSDictionary * myProcesses;
  NSString * myModel;
  NSMutableDictionary * myDiagnosticEvents;
  NSMutableDictionary * myAdwareFiles;
  NSArray * myAdwareExtensions;
  NSString * myComputerName;
  NSString * myHostName;
  bool myAdwareFound;
  }

// Keep track of the OS version.
@property (assign) int majorOSVersion;

// Keep track of system volumes.
@property (retain) NSMutableDictionary * volumes;

// Keep track of CoreStorage volumes.
@property (retain) NSMutableDictionary * coreStorageVolumes;

// Keep track of disk errors.
@property (retain) NSMutableDictionary * diskErrors;

// Keep track of log content.
@property (retain) NSArray * logEntries;

// Keep track of applications.
@property (retain) NSDictionary * applications;

// I will need the RAM amount (in GB) for later.
@property (assign) int physicalRAM;

// See if I can get the machine image.
@property (retain) NSImage * machineIcon;

// All processes.
@property (retain) NSDictionary * processes;

// The model code.
@property (retain) NSString * model;

// Diagnostic events.
@property (retain) NSMutableDictionary * diagnosticEvents;

// Adware files.
@property (retain) NSMutableDictionary * adwareFiles;

// Adware extensions.
@property (retain) NSArray * adwareExtensions;

// Localized host name.
@property (retain) NSString * computerName;

// Host name.
@property (retain) NSString * hostName;

// Did I find any adware?
@property (assign) bool adwareFound;

// Return the singeton of shared values.
+ (Model *) model;

// Return true if there are log entries for a process.
- (bool) hasLogEntries: (NSString *) name;

// Collect log entires matching a date.
- (NSString *) logEntriesAround: (NSDate *) date;

// Create a details URL for a query string.
- (NSAttributedString *) getDetailsURLFor: (NSString *) query;

// Is this file an adware file?
- (bool) isAdware: (NSString *) path;

// Is this file an adware extension?
- (bool) isAdwareExtension: (NSString *) path;

// What kind of adware is this?
- (NSString *) adwareType: (NSString *) path;

@end
