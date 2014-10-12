/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "SystemInformation.h"

@implementation SystemInformation

@synthesize majorOSVersion = myMajorOSVersion;
@synthesize volumes = myVolumes;
@synthesize applications = myApplications;
@synthesize physicalRAM = myPhysicalRAM;
@synthesize machineIcon = myMachineIcon;
@synthesize processes = myProcesses;
@synthesize model = myModel;

// Return the singeton of shared values.
+ (SystemInformation *) sharedInformation
  {
  static SystemInformation * information = nil;
  
  static dispatch_once_t onceToken;
  
  dispatch_once(
    & onceToken,
    ^{
      information = [[SystemInformation alloc] init];
    });
    
  return information;
  }

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    myVolumes = [[NSMutableDictionary alloc] init];
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  self.volumes = nil;
  self.applications = nil;
  self.machineIcon = nil;
  self.processes = nil;
  
  [super dealloc];
  }

@end
