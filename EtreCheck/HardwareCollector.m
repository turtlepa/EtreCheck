/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "HardwareCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "TTTLocalizedPluralString.h"
#import "NSArray+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import <SystemConfiguration/SystemConfiguration.h>

// Some keys to be returned from machine lookuup.
#define kMachineIcon @"machineicon"
#define kMachineName @"machinename"

// Collect hardware information.
@implementation HardwareCollector

@synthesize properties = myProperties;
@synthesize machineIcon = myMachineIcon;
@synthesize marketingName = myMarketingName;
@synthesize EnglishMarketingName = myEnglishMarketingName;

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"hardware";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    
    // Do this in the constructor so the data is available before
    // collection starts.
    [self loadProperties];    
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  self.machineIcon = nil;
  self.properties = nil;
  
  [super dealloc];
  }

// Load machine properties.
- (void) loadProperties
  {
  // First look for a machine attributes file.
  self.properties =
    [NSDictionary
      readPropertyList: NSLocalizedString(@"machineattributes", NULL)];
    
  // Don't give up yet. Try the old one too.
  if(!self.properties)
    self.properties =
      [NSDictionary
        readPropertyList:
          NSLocalizedString(@"oldmachineattributes", NULL)];
    
  // Load a manual machine image lookup table.
  [self loadMachineImageLookupTable];
  
  // This is as good a place as any to collect this.
  NSString * computerName = (NSString *)SCDynamicStoreCopyComputerName(NULL, NULL);

  NSString * hostName = (NSString *)SCDynamicStoreCopyLocalHostName(NULL);

  [[Model model] setComputerName: computerName];
  [[Model model] setHostName: hostName];
  
  [computerName release];
  [hostName release];
  }

// Load a manual machine image lookup table in case there isn't a system-
// provided one available.
- (void) loadMachineImageLookupTable
  {
  myMachineImageLookup =
    @{
      @"MacBookPro7,1" :  @"com.apple.macbookpro-13-unibody.icns",
      @"MacBookPro8,2" :  @"com.apple.macbookpro-15-unibody.icns",
      @"MacBookPro8,3" :  @"com.apple.macbookpro-17-unibody.icns",
      @"iMac13,1" :       @"com.apple.imac-unibody-21-no-optical.icns",
      @"iMac13,2" :       @"com.apple.imac-unibody-27-no-optical.icns",
      @"MacBookPro10,2" : @"com.apple.macbookpro-13-retina-display.icns",
      @"MacBookPro11,2" : @"com.apple.macbookpro-15-retina-display.icns",
      @"Macmini1,1" :     @"com.apple.macmini.icns",
      @"Macmini4,1" :     @"com.apple.macmini-unibody.icns",
      @"Macmini5,1" :     @"com.apple.macmini-unibody-no-optical.icns",
      @"MacBook5,2" :     @"com.apple.macbook-unibody-plastic.icns",
      @"MacBook8,1" :     @"com.apple.macbookair-13-unibody.icns",
      @"MacPro2,1" :      @"com.apple.macpro.icns",
      @"MacPro6,1" :      @"com.apple.macpro-cylinder.icns",
      @"MacBookAir3,1" :  @"com.apple.macbookair-11-unibody.icns",
      @"MacBookAir3,2" :  @"com.apple.macbookair-13-unibody.icns"
    };
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking hardware information", NULL)];

  NSArray * args =
    @[
      @"-xml",
      @"SPHardwareDataType"
    ];
  
  NSData * result =
    [Utilities execute: @"/usr/sbin/system_profiler" arguments: args];
  
  if(result)
    {
    NSArray * plist = [NSArray readPropertyListData: result];
  
    if(plist && [plist count])
      {
      NSArray * infos =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([infos count])
        {
        [self.result appendAttributedString: [self buildTitle]];

        for(NSDictionary * info in infos)
          [self printMachineInformation: info];
          
        [self printBluetoothInformation];
        [self printWirelessInformation];
        [self printBatteryInformation];
        
        [self.result appendCR];
        }
      }
    }
    
  dispatch_semaphore_signal(self.complete);
  }

// Print informaiton for the machine.
- (void) printMachineInformation: (NSDictionary *) info
  {
  NSString * name = [info objectForKey: @"machine_name"];
  NSString * model = [info objectForKey: @"machine_model"];
  NSString * cpu_type = [info objectForKey: @"cpu_type"];
  NSNumber * core_count =
    [info objectForKey: @"number_processors"];
  NSString * speed =
    [info objectForKey: @"current_processor_speed"];
  NSNumber * cpu_count = [info objectForKey: @"packages"];
  NSString * memory = [info objectForKey: @"physical_memory"];
  NSString * serial = [info objectForKey: @"serial_number"];

  [[Model model] setModel: model];
  
  // Extract the memory.
  [[Model model]
    setPhysicalRAM: [self parseMemory: memory]];

  // Print the human readable machine name, if I can find one.
  [self printHumanReadableMacName: serial code: model];
    
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(@"    %@ - %@: %@\n", NULL),
          name, NSLocalizedString(@"model", NULL), model]];
    
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(
            @"    %@ %@ %@ CPU: %@-core\n", NULL),
          cpu_count,
          speed,
          cpu_type ? cpu_type : @"",
          core_count]];
    
  [self printMemory: memory];
  }

// Parse a memory string into an int (in GB).
- (int) parseMemory: (NSString *) memory
  {
  NSScanner * scanner = [NSScanner scannerWithString: memory];

  int physicalMemory;
  
  if(![scanner scanInt: & physicalMemory])
    physicalMemory = 0;

  return physicalMemory;
  }

// Extract a "marketing name" for a machine from a serial number.
- (void) printHumanReadableMacName: (NSString *) serial
  code: (NSString *) code
  {
  // Try to get the marketing name from Apple.
  [self askAppleForMarketingName: serial];
  
  NSString * verified = @"";
  
  NSString * technicalSpecificationsURL = nil;
  
  if([self.EnglishMarketingName length])
    {
    verified = NSLocalizedString(@"(Verified)", NULL);
  
    technicalSpecificationsURL = [self getTechnicalSpecificationsURL];
    }
    
  // Get information on my own.
  NSDictionary * machineProperties = [self lookupMachineProperties: code];
  
  if(machineProperties)
    {
    if(![self.marketingName length])
      self.marketingName = [machineProperties objectForKey: kMachineName];

    [[Model model]
      setMachineIcon: [machineProperties objectForKey: kMachineIcon]];
    }

  [self.result
    appendString:
      [NSString
        stringWithFormat: @"    %@ ", self.marketingName]];
      
  if(technicalSpecificationsURL)
    [self.result
      appendAttributedString:
        [Utilities
          buildURL: technicalSpecificationsURL
          title: NSLocalizedString(@"(Technical Specifications)", NULL)]];
  else
    [self.result appendString: verified];
      
  [self.result appendString: @"\n"];
  }

// Get a technical specifications URL, falling back to English,
// if necessary.
- (NSString *) getTechnicalSpecificationsURL
  {
  NSString * url =
    NSLocalizedStringFromTable(
      self.marketingName, @"TechnicalSpecifications", NULL);
    
  if([url isEqualToString: self.marketingName])
    url =
      NSLocalizedStringFromTableInBundle(
        self.EnglishMarketingName,
        @"TechnicalSpecifications",
        [[Utilities shared] EnglishBundle],
        NULL);
    
  if([url isEqualToString: self.marketingName])
    return nil;
    
  return url;
  }

// Try to get the marketing name directly from Apple.
- (void) askAppleForMarketingName: (NSString *) serial
  {
  NSString * language = NSLocalizedString(@"en", NULL);
  
  self.marketingName =
    [self askAppleForMarketingName: serial language: language];
  
  if([language isEqualToString: @"en"])
    self.EnglishMarketingName = self.marketingName;
  else
    self.EnglishMarketingName =
      [self askAppleForMarketingName: serial language: @"en"];
  }

// Try to get the marketing name directly from Apple.
- (NSString *) askAppleForMarketingName: (NSString *) serial
  language: (NSString *) language
  {
  NSString * marketingName = @"";
  
  if(serial)
    {
    NSString * code = [serial substringFromIndex: 8];

    NSURL * url =
      [NSURL
        URLWithString:
          [NSString
            stringWithFormat:
              @"http://support-sp.apple.com/sp/product?cc=%@&lang=%@",
              code, language]];
    
    NSError * error = nil;
    
    NSXMLDocument * document =
      [[NSXMLDocument alloc]
        initWithContentsOfURL: url options: 0 error: & error];
    
    if(document)
      {
      NSArray * nodes =
        [document nodesForXPath: @"root/configCode" error: & error];

      if(nodes && [nodes count])
        {
        NSXMLNode * configCodeNode = [nodes objectAtIndex: 0];
        
        // Apple has non-breaking spaces in the results, especially in
        // French but sometimes in English too.
        NSString * nbsp = @"\u00A0";
        
        marketingName =
          [[configCodeNode stringValue]
            stringByReplacingOccurrencesOfString: nbsp withString: @" "];
        }
      
      [document release];
      }
    }
    
  return marketingName;
  }

// Try to get information about the machine from system resources.
- (NSDictionary *) lookupMachineProperties: (NSString *) code
  {
  // If I have a machine code, try to look up the built-in attributes.
  if(code)
    if(self.properties)
      {
      NSDictionary * modelInfo = [self.properties objectForKey: code];
      
      // Load the machine image.
      self.machineIcon = [self findMachineIcon: code];
      
      // Get machine name.
      NSString * machineName = [self lookupMachineName: modelInfo];
        
      // Fallback.
      if(!machineName)
        machineName = code;
        
      NSMutableDictionary * result = [NSMutableDictionary dictionary];
      
      [result setObject: machineName forKey: kMachineName];
      
      if(self.machineIcon)
        [result setObject: self.machineIcon forKey: kMachineIcon];
        
      return result;
      }
  
  return nil;
  }

// Get the machine name.
- (NSString *) lookupMachineName: (NSDictionary *) machineInformation
  {
  // Now get the machine name.
  NSDictionary * localizedModelInfo =
    [machineInformation objectForKey: @"_LOCALIZABLE_"];
    
  // New machines.
  NSString * machineName =
    [localizedModelInfo objectForKey: @"marketingModel"];

  // Older machines.
  if(!machineName)
    machineName = [localizedModelInfo objectForKey: @"description"];
    
  return machineName;
  }

// Find a machine icon.
- (NSImage *) findMachineIcon: (NSString *) code
  {
  NSDictionary * machineInformation = [self.properties objectForKey: code];
      
  // Load the machine image.
  NSString * iconPath =
    [machineInformation objectForKey: @"hardwareImageName"];
  
  // Don't give up.
  if(!iconPath)
    {
    NSString * fileName = [myMachineImageLookup objectForKey: code];
    
    if(fileName)
      {
      NSString * resourcePath =
        @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources";
        
      iconPath = [resourcePath stringByAppendingPathComponent: fileName];
      
      if(![[NSFileManager defaultManager] fileExistsAtPath: iconPath])
        iconPath = nil;
      }
    }
    
  if(!iconPath)
    return nil;

  return [[[NSImage alloc] initWithContentsOfFile: iconPath] autorelease];
  }

// Print memory, flagging insufficient amounts.
- (void) printMemory: (NSString *) memory
  {
  NSDictionary * details = [self collectMemoryDetails];
  
  NSString * upgradeable = @"";
  
  if(details)
    {
    NSString * isUpgradeable =
      [details objectForKey: @"is_memory_upgradeable"];
    
    // Snow Leopoard doesn't seem to report this.
    if(isUpgradeable)
      upgradeable =
        [isUpgradeable boolValue]
          ? NSLocalizedString(@"Upgradeable", NULL)
          : NSLocalizedString(@"Not upgradeable", NULL);
    }
    
  if([[Model model] physicalRAM] < 4)
    {
    [self.result
      appendString:
        [NSString stringWithFormat: @"    %@ RAM %@\n", memory, upgradeable]
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];
    }
  else
    [self.result
      appendString:
        [NSString
          stringWithFormat: @"    %@ RAM %@\n", memory, upgradeable]];

  if(details)
    {
    NSArray * banks = [details objectForKey: @"_items"];
    
    if(banks)
      [self printMemoryBanks: banks];
    }
  }

- (NSDictionary *) collectMemoryDetails
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPMemoryDataType"
    ];
  
  NSData * result =
    [Utilities execute: @"/usr/sbin/system_profiler" arguments: args];
  
  if(result)
    {
    NSArray * plist = [NSArray readPropertyListData: result];
  
    if(plist && [plist count])
      {
      NSArray * infos =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([infos count])
        return [infos objectAtIndex: 0];
      }
    }
    
  return nil;
  }

// Print memory banks.
- (void) printMemoryBanks: (NSArray *) banks
  {
  NSString * lastBankID = nil;
  NSString * lastBankInfo = nil;
  int bankCount = 0;
  
  for(NSDictionary * bank in banks)
    {
    NSString * name = [bank objectForKey: @"_name"];
    NSString * size = [bank objectForKey: @"dimm_size"];
    NSString * type = [bank objectForKey: @"dimm_type"];
    NSString * speed = [bank objectForKey: @"dimm_speed"];
    NSString * status = [bank objectForKey: @"dimm_status"];
    
    NSString * currentBankID =
      [NSString stringWithFormat: @"        %@", name];
      
    if([size isEqualToString: @"(empty)"])
      size = @"empty";
      
    if([size isEqualToString: @"empty"])
      {
      size = NSLocalizedString(@"Empty", NULL);
      type = @"";
      speed = @"";
      status = @"";
      }
      
    NSString * currentBankInfo =
      [NSString
        stringWithFormat:
          @"            %@ %@ %@ %@\n", size, type, speed, status];
      
    bool sameID = [lastBankID isEqualToString: currentBankID];
    bool sameInfo = [lastBankInfo isEqualToString: currentBankInfo];
    
    if(sameID && sameInfo && (bank != [banks lastObject]))
      ++bankCount;
    else
      {
      [self.result appendString: currentBankID];
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"%@\n",
              bankCount > 0
                ? [NSString stringWithFormat: @" (%d)", bankCount]
                : @""]];
      [self.result appendString: currentBankInfo];
      
      lastBankID = currentBankID;
      lastBankInfo = currentBankInfo;
      }
    }
  }

// Print information about bluetooth.
- (void) printBluetoothInformation
  {
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          @"    Bluetooth: %@\n", [self collectBluetoothInformation]]];
  }

// Collect bluetooth information.
- (NSString *) collectBluetoothInformation
  {
  if([self supportsContinuity])
    return NSLocalizedString(@"Good - Handoff/Airdrop2 supported", NULL);
              
  return NSLocalizedString(@"Old - Handoff/Airdrop2 not supported", NULL);
  }

// Is continuity supported?
- (bool) supportsContinuity
  {
  NSString * model = [[Model model] model];
  
  NSString * specificModel = nil;
  int target = 0;
  int number = 0;
  
  if([model hasPrefix: @"MacBookPro"])
    {
    specificModel = @"MacBookPro";
    target = 9;
    }
  else if([model hasPrefix: @"iMac"])
    {
    specificModel = @"iMac";
    target = 13;
    }
  else if([model hasPrefix: @"MacPro"])
    {
    specificModel = @"MacPro";
    target = 6;
    }
  else if([model hasPrefix: @"MacBookAir"])
    {
    specificModel = @"MacBookAir";
    target = 5;
    }
  else if([model hasPrefix: @"Macmini"])
    {
    specificModel = @"Macmini";
    target = 6;
    }
    
  if(specificModel)
    {
    NSScanner * scanner = [NSScanner scannerWithString: model];
    
    if([scanner scanString: specificModel intoString: NULL])
      if([scanner scanInt: & number])
        return number >= target;
    }
    
  return NO;
  }

// Print wireless information.
- (void) printWirelessInformation
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPAirPortDataType"
    ];
  
  NSData * result =
    [Utilities execute: @"/usr/sbin/system_profiler" arguments: args];
  
  if(result)
    {
    NSArray * plist = [NSArray readPropertyListData: result];
  
    if(plist && [plist count])
      {
      NSArray * infos =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([infos count])
        {
        for(NSDictionary * info in infos)
          {
          NSArray * interfaces =
            [info objectForKey: @"spairport_airport_interfaces"];
            
          NSUInteger count = [interfaces count];
          
          if(interfaces)
            [self.result
              appendString:
                [NSString
                  stringWithFormat:
                    @"    Wireless: %@",
                    TTTLocalizedPluralString(count, @"interface", nil)]];
          
          for(NSDictionary * interface in interfaces)
            [self
              printWirelessInterface: interface
              indent: count > 1 ? @"        " : @" "];
          }
        }
      }
    }
  }

// Print a single wireless interface.
- (void) printWirelessInterface: (NSDictionary *) interface
  indent: (NSString *) indent
  {
  NSString * name = [interface objectForKey: @"_name"];
  NSString * modes =
    [interface objectForKey: @"spairport_supported_phymodes"];

  if([modes length])
    [self.result
      appendString:
        [NSString stringWithFormat: @"%@%@: %@\n", indent, name, modes]];
  else
    [self.result appendString: NSLocalizedString(@"Unknown", NULL)];
  }

// Print battery information.
- (void) printBatteryInformation
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPPowerDataType"
    ];
  
  NSData * result =
    [Utilities execute: @"/usr/sbin/system_profiler" arguments: args];
  
  if(result)
    {
    NSArray * plist = [NSArray readPropertyListData: result];
  
    if(plist && [plist count])
      {
      NSArray * infos =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([infos count])
        [self printBatteryInformation: infos];
      }
    }
  }

// Print battery information.
- (void) printBatteryInformation: (NSArray *) infos
  {
  NSNumber * cycleCount = nil;
  NSString * health = nil;
  NSString * serialNumber = @"";
  
  for(NSDictionary * info in infos)
    {
    NSDictionary * healthInfo =
      [info objectForKey: @"sppower_battery_health_info"];
      
    if(healthInfo)
      {
      cycleCount =
        [healthInfo objectForKey: @"sppower_battery_cycle_count"];
      health = [healthInfo objectForKey: @"sppower_battery_health"];
      }

    NSDictionary * modelInfo =
      [info objectForKey: @"sppower_battery_model_info"];
      
    if(modelInfo)
      serialNumber =
        [modelInfo objectForKey: @"sppower_battery_serial_number"];
    }
    
  if(cycleCount && [health length])
    [self.result
      appendString:
          [NSString
            stringWithFormat:
              NSLocalizedString(
                @"    Battery: Health = %@ - Cycle count = %@ - SN = %@\n",
                NULL),
              NSLocalizedString(health, NULL), cycleCount, serialNumber]];
  }

@end
