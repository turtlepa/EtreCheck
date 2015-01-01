/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "VideoCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"

@implementation VideoCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"video";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Collect video information.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Checking video information", NULL)];

  NSArray * args =
    @[
      @"-xml",
      @"SPDisplaysDataType"
    ];
  
  NSData * result =
    [Utilities execute: @"/usr/sbin/system_profiler" arguments: args];
  
  if(result)
    {
    NSArray * plist = [NSArray readPropertyListData: result];
  
    if(plist && [plist count])
      {
      NSArray * infos = [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([infos count])
        [self printVideoInformation: infos];
      }
    }
    
  dispatch_semaphore_signal(self.complete);
  }

// Print video information.
- (void) printVideoInformation: (NSArray *) infos
  {
  [self.result appendAttributedString: [self buildTitle]];
  
  for(NSDictionary * info in infos)
    {
    NSString * name = [info objectForKey: @"sppci_model"];
    
    if(![name length])
      name = NSLocalizedString(@"Unknown", NULL);
      
    NSString * vramAmount = [info objectForKey: @"spdisplays_vram"];

    NSString * vram = @"";
    
    if(vramAmount)
      vram =
        [NSString
          stringWithFormat:
            NSLocalizedString(@"VRAM: %@", NULL), vramAmount];
      
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"\t%@%@%@\n",
            name ? name : @"",
            [vram length] ? @" - " : @"",
            vram]];
      
    NSArray * displays = [info objectForKey: @"spdisplays_ndrvs"];
  
    for(NSDictionary * display in displays)
      [self printDisplayInfo: display];
    }
    
  [self.result appendCR];
  }

// Print information about a display.
- (void) printDisplayInfo: (NSDictionary *) display
  {
  NSString * name = [display objectForKey: @"_name"];
  
  if([name isEqualToString: @"spdisplays_display"])
    name = NSLocalizedString(@"Display", NULL);
    
  NSString * resolution = [display objectForKey: @"spdisplays_resolution"];

  if(name || resolution)
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"\t\t%@ %@\n",
            name ? name : @"Unknown",
            resolution ? resolution : @""]];
  }

@end
