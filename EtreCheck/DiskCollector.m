/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "DiskCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "ByteCountFormatter.h"
#import "NSArray+Etresoft.h"
#import "TTTLocalizedPluralString.h"

// Some keys for an internal dictionary.
#define kDiskType @"volumetype"
#define kDiskStatus @"volumestatus"
#define kAttributes @"attributes"

// Collect information about disks.
@implementation DiskCollector

@dynamic volumes;
@dynamic coreStorageVolumes;

// Provide easy access to volumes.
- (NSMutableDictionary *) volumes
  {
  return [[Model model] volumes];
  }

// Provide easy access to coreStorageVolumes.
- (NSMutableDictionary *) coreStorageVolumes
  {
  return [[Model model] coreStorageVolumes];
  }

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.progressEstimate = 0.4;
    self.name = @"diskinformation";
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Checking disk information", NULL)];

  NSArray * args =
    @[
      @"-xml",
      @"SPSerialATADataType"
    ];
  
  NSData * result =
    [Utilities execute: @"/usr/sbin/system_profiler" arguments: args];
  
  if(result)
    {
    NSArray * plist = [NSArray readPropertyListData: result];
  
    if(plist && [plist count])
      {
      [self.result
        appendAttributedString: [self buildTitle: @"Disk Information:"]];
      
      NSDictionary * controllers =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      for(NSDictionary * controller in controllers)
        [self printController: controller];
      }
    }
  else
    [self.result appendCR];
    
  [self
    setTabs: @[@28, @56, @84]
    forRange: NSMakeRange(0, [self.result length])];

  dispatch_semaphore_signal(self.complete);
  }

// Print disks attached to a single controller.
- (void) printController: (NSDictionary *) controller
  {
  NSDictionary * disks = [controller objectForKey: @"_items"];
  
  for(NSDictionary * disk in disks)
    {
    NSString * diskName = [disk objectForKey: @"_name"];
    NSString * diskDevice = [disk objectForKey: @"bsd_name"];
    NSString * diskSize = [disk objectForKey: @"size"];
    NSString * UUID = [disk objectForKey: @"volume_uuid"];
    
    if(!diskDevice)
      diskDevice = @"";
      
    if(!diskSize)
      diskSize = @"";
    else
      diskSize = [NSString stringWithFormat: @": (%@)", diskSize];

    if(UUID)
      [self.volumes setObject: disk forKey: UUID];

    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"\t%@ %@ %@\n",
            diskName ? diskName : @"-", diskDevice, diskSize]];
    
    [self collectSMARTStatus: disk indent: @"\t"];
    
    [self printDiskVolumes: disk];
    
    [self.result appendCR];
    }
  }

// Print the volumes on a disk.
- (void) printDiskVolumes: (NSDictionary *) disk
  {
  NSArray * volumes = [disk objectForKey: @"volumes"];
  NSMutableSet * coreStorageVolumeNames = [NSMutableSet set];

  if(volumes && [volumes count])
    {
    for(NSDictionary * volume in volumes)
      {
      NSString * iocontent = [volume objectForKey: @"iocontent"];
      
      if([iocontent isEqualToString: @"Apple_CoreStorage"])
        {
        NSString * name = [volume objectForKey: @"_name"];
        
        [coreStorageVolumeNames addObject: name];
        }
        
      else
        [self printVolume: volume indent: @"\t\t"];
      }
      
    for(NSDictionary * name in coreStorageVolumeNames)
      {
      NSDictionary * coreStorageVolume =
        [self.coreStorageVolumes objectForKey: name];
        
      if(coreStorageVolume)
        [self printCoreStorageVolume: coreStorageVolume indent: @"\t\t"];
      }
    }
  }

// Get the SMART status for this disk.
- (void) collectSMARTStatus: (NSDictionary *) disk
  indent: (NSString *) indent
  {
  NSString * smart_status = [disk objectForKey: @"smart_status"];

  if(!smart_status)
    return;
    
  BOOL smart_not_supported =
    [smart_status isEqualToString: @"Not Supported"];
  
  BOOL smart_verified =
    [smart_status isEqualToString: @"Verified"];

  if(!smart_not_supported && !smart_verified)
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            NSLocalizedString(@"%@S.M.A.R.T. Status: %@\n", NULL),
            indent, smart_status]
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];
  else
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            NSLocalizedString(@"%@S.M.A.R.T. Status: Verified\n", NULL),
            indent]];
  }

// Print information about a Core Storage volume.
- (void) printCoreStorageVolume: (NSDictionary *) volume
  indent: (NSString *) indent
  {
  [self printVolume: volume indent: indent];
  
  indent = [indent stringByAppendingString: @"\t"];
  
  NSDictionary * lv = [volume objectForKey: @"com.apple.corestorage.lv"];
  
  if(lv)
    [self printCoreStorageLvInformation: lv indent: indent];
    
  NSArray * pvs = [volume objectForKey: @"com.apple.corestorage.pv"];
  
  if(pvs)
    [self printCoreStoragePvInformation: pvs indent: indent];
  }

// Print Core Storage "lv" information about a volume.
- (void) printCoreStorageLvInformation: (NSDictionary *) lv
  indent: (NSString *) indent
  {
  NSString * state =
    [lv objectForKey: @"com.apple.corestorage.lv.conversionState"];
  NSString * encrypted =
    [lv objectForKey: @"com.apple.corestorage.lv.encrypted"];
  NSString * encryptionType =
    [lv objectForKey: @"com.apple.corestorage.lv.encryptionType"];
  NSString * locked =
    [lv objectForKey: @"com.apple.corestorage.lv.locked"];
    
  if(!encryptionType)
    encryptionType = @"";
    
  if(!state)
    state = @"";
    
  if([encrypted isEqualToString: @"yes"])
    {
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"%@%@ %@ %@",
            indent,
            NSLocalizedString(@"Encrypted", NULL),
            encryptionType,
            [locked isEqualToString: @"yes"]
              ? NSLocalizedString(@"Locked", NULL)
              : NSLocalizedString(@"Unlocked", NULL)]];

    if(![state isEqualToString: @"Complete"])
      [self.result
        appendString: state
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] blue],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
      
    [self.result appendCR];
    }
  }

// Print Core Storage "pv" information about a volume.
- (void) printCoreStoragePvInformation: (NSArray *) pvs
  indent: (NSString *) indent
  {
  for(NSDictionary * pv in pvs)
    {
    NSString * name = [pv objectForKey: @"_name"];
    NSString * status =
      [pv objectForKey: @"com.apple.corestorage.pv.status"];

    NSNumber * pvSize =
      [pv objectForKey: @"com.apple.corestorage.pv.size"];
    
    NSString * size = @"";
    
    if(pvSize)
      {
      ByteCountFormatter * formatter = [ByteCountFormatter new];
      
      size =
        [formatter stringFromByteCount: [pvSize unsignedLongLongValue]];
        
      [formatter release];
      }

    NSString * errors = [self errorsFor: name];
    
    status = [status stringByAppendingString: errors];
    
    if([errors length])
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"%@Core Storage: %@ %@ %@", indent, name, size, status]
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
    else
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"%@Core Storage: %@ %@ %@", indent, name, size, status]];

    [self.result appendCR];
    }
  }

// Print information about a volume.
- (void) printVolume: (NSDictionary *) volume indent: (NSString *) indent
  {
  NSString * volumeName = [volume objectForKey: @"_name"];
  NSString * volumeMountPoint = [volume objectForKey: @"mount_point"];
  NSString * volumeDevice = [volume objectForKey: @"bsd_name"];
  NSString * volumeSize = [self volumeSize: volume];
  NSString * volumeFree = [self volumeFreeSpace: volume];
  NSString * UUID = [volume objectForKey: @"volume_uuid"];

  if(!volumeMountPoint)
    volumeMountPoint = NSLocalizedString(@"<not mounted>", NULL);
    
  if(UUID)
    [self.volumes setObject: volume forKey: UUID];

  NSDictionary * stats =
    [self
      volumeStatsFor: volumeName
      at: volumeMountPoint
      available:
        [[volume objectForKey: @"free_space_in_bytes"]
          unsignedLongLongValue]];

  NSDictionary * attributes = [stats objectForKey: kAttributes];
  
  NSString * errors = [self errorsFor: volumeDevice];
  
  if([errors length])
    attributes =
      @{
        NSForegroundColorAttributeName : [[Utilities shared] red],
        NSFontAttributeName : [[Utilities shared] boldFont]
      };

  NSString * status =
    [[stats objectForKey: kDiskStatus] stringByAppendingString: errors];

  NSString * volumeInfo =
    [NSString
      stringWithFormat:
        NSLocalizedString(@"%@%@ (%@) %@ %@: %@ %@%@\n", NULL),
        indent,
        volumeName ? volumeName : @"-",
        volumeDevice,
        volumeMountPoint,
        [stats objectForKey: kDiskType],
        volumeSize,
        volumeFree,
        status];
    
  if(attributes)
    [self.result appendString: volumeInfo attributes: attributes];
  else
    [self.result appendString: volumeInfo];
  }

// Get the size of a volume.
- (NSString *) volumeSize: (NSDictionary *) volume
  {
  NSString * size = nil;
  
  NSNumber * sizeInBytes =
    [volume objectForKey: @"size_in_bytes"];
  
  if(sizeInBytes)
    {
    ByteCountFormatter * formatter = [ByteCountFormatter new];
    
    size =
      [formatter
        stringFromByteCount: [sizeInBytes unsignedLongLongValue]];
      
    [formatter release];
    }

  if(!size)
    size = [volume objectForKey: @"size"];

  if(!size)
    size = NSLocalizedString(@"Size unknown", NULL);
    
  return size;
  }

// Get the free space on the volume.
- (NSString *) volumeFreeSpace: (NSDictionary *) volume
  {
  NSString * volumeFree = nil;
  
  NSNumber * freeSpaceInBytes =
    [volume objectForKey: @"free_space_in_bytes"];
  
  if(freeSpaceInBytes)
    {
    ByteCountFormatter * formatter = [ByteCountFormatter new];
    
    volumeFree =
      [formatter
        stringFromByteCount: [freeSpaceInBytes unsignedLongLongValue]];
      
    [formatter release];
    }

  if(!volumeFree)
    volumeFree = [volume objectForKey: @"free_space"];

  if(!volumeFree)
    volumeFree = @"";
  else
    volumeFree =
      [NSString
        stringWithFormat:
          NSLocalizedString(@"(%@ free)", NULL), volumeFree];
    
  return volumeFree;
  }

// Get more information about a volume.
- (NSDictionary *) volumeStatsFor: (NSString *) name
  at: (NSString *) mountPoint available: (unsigned long long) free
  {
  NSString * type = NSLocalizedString(@"", NULL);
  NSString * status = NSLocalizedString(@"", NULL);
  NSDictionary * attributes = @{};
  
  if([mountPoint isEqualToString: @"/"])
    {
    unsigned long long GB = 1024 * 1024 * 1024;

    if(free < (GB * 15))
      {
      type = NSLocalizedString(@" [Startup]", NULL);
      status = NSLocalizedString(@" (Low!)", NULL);
      }
    }
    
  else if([name isEqualToString: @"Recovery HD"])
    {
    type = NSLocalizedString(@" [Recovery]", NULL);
    attributes =
      @{
        NSForegroundColorAttributeName : [[Utilities shared] gray]
      };
    }
    
  if([status length] && ![attributes count])
    attributes =
      @{
        NSForegroundColorAttributeName : [[Utilities shared] red],
        NSFontAttributeName : [[Utilities shared] boldFont]
      };

  return
    @{
      kDiskType : type,
      kDiskStatus : status,
      kAttributes : attributes
    };
  }

// Get more information about a device.
- (NSString *) errorsFor: (NSString *) name
  {
  NSNumber * errors =
    [[[Model model] diskErrors] objectForKey: name];
    
  int errorCount = [errors intValue];
  
  if(errorCount)
    return
      [NSString
        stringWithFormat:
          NSLocalizedString(@" - %@", NULL),
          TTTLocalizedPluralString(errorCount, @"error", NULL)];

  return NSLocalizedString(@"", NULL);
  }

@end
