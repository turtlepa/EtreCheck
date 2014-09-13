/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "ProcessesCollector.h"
#import "SystemInformation.h"
#import "Utilities.h"

// Collect information about processes.
@implementation ProcessesCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    self.progressEstimate = 3.0;
    
  return self;
  }

// Collect running processes.
- (NSMutableDictionary *) collectProcesses
  {
  NSArray * args = @[ @"-raxcww", @"-o", @"%mem, %cpu, comm" ];
  
  NSData * result = [Utilities execute: @"/bin/ps" arguments: args];
  
  NSArray * lines = [Utilities formatLines: result];
  
  NSMutableDictionary * processes = [NSMutableDictionary dictionary];
  
  for(NSString * line in lines)
    {
    if([line hasPrefix: @"STAT"])
      continue;

    NSNumber * mem = nil;
    NSNumber * cpu = nil;
    NSString * command = nil;

    [self parsePs: line mem: & mem cpu: & cpu command: & command];

    if([command isEqualToString: @"EtreCheck"])
      continue;
      
    double RAM = [[SystemInformation sharedInformation] physicalRAM];
    
    RAM = RAM * 1024 * 1024 * 1024;
    
    double usage = ([mem doubleValue] / 100.0) * RAM;
      
    NSDictionary * dict =
      [NSDictionary
        dictionaryWithObjectsAndKeys:
          [NSNumber numberWithDouble: usage], @"mem",
          cpu, @"cpu",
          nil];
      
    if(cpu && command)
      [processes setObject: dict forKey: command];
    }
                      
  return processes;
  }

// Parse a line from the ps command.
- (void) parsePs: (NSString *) line
  mem: (NSNumber **) mem
  cpu: (NSNumber **) cpu
  command: (NSString **) command
  {
  NSScanner * scanner = [NSScanner scannerWithString: line];

  double memValue;
  
  BOOL found = [scanner scanDouble: & memValue];

  if(!found)
    return;

  *mem = [NSNumber numberWithDouble: memValue];
  
  double cpuValue;

  found = [scanner scanDouble: & cpuValue];

  if(!found)
    return;

  *cpu = [NSNumber numberWithDouble: cpuValue];

  [scanner scanUpToString: @"\n" intoString: command];
  }

// Sort process names by some values measurement.
- (NSArray *) sortProcesses: (NSDictionary *) processes
  {
  NSMutableArray * sorted = [NSMutableArray array];
  
  for(NSString * command in processes)
    [sorted
      addObject:
        [NSDictionary
          dictionaryWithObject: [processes objectForKey: command]
          forKey: command]];
  
  [sorted
    sortUsingComparator:
      ^(id obj1, id obj2)
        {
        NSArray * values1 = [obj1 allValues];
        NSArray * values2 = [obj2 allValues];

        if(values1 && values2 && [values1 count] && [values2 count])
          {
          NSNumber * value1 = [values1 objectAtIndex: 0];
          NSNumber * value2 = [values2 objectAtIndex: 0];
          
          if([value1 doubleValue] < [value2 doubleValue])
            return (NSComparisonResult)NSOrderedDescending;
            
          if ([value1 doubleValue] > [value2 doubleValue])
            return (NSComparisonResult)NSOrderedAscending;
          }

        return (NSComparisonResult)NSOrderedSame;
        }];
  
  return sorted;
  }

@end
