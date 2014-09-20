/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "MemoryUsageCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "ByteCountFormatter.h"

// Collect information about memory usage.
@implementation MemoryUsageCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    self.name = @"memory";
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self updateStatus: NSLocalizedString(@"Sampling processes", NULL)];

  // Collect the average memory usage usage for all processes (5 times).
  NSDictionary * avgMemory = [self collectAverageMemory];
  
  // Sort the result by average value.
  NSArray * processesMemory = [self sortProcesses: avgMemory];
  
  // Print the top processes.
  [self printTopProcesses: processesMemory];
    
  dispatch_semaphore_signal(self.complete);
  }

// Collect the average CPU usage of all processes.
- (NSDictionary *) collectAverageMemory
  {
  NSMutableDictionary * avgMem = [NSMutableDictionary dictionary];
  
  for(NSUInteger i = 0; i < 5; ++i)
    {
    usleep(500000);
    
    NSDictionary * current = [self collectProcesses];
    
    for(NSString * command in current)
      {
      NSNumber * currentMem =
        [[current objectForKey: command] objectForKey: @"mem"];
      NSNumber * previousMem = [avgMem objectForKey: command];

      if(!previousMem)
        [avgMem setObject: currentMem forKey: command];
      else if(previousMem && currentMem)
        {
        double totalMem = [previousMem doubleValue] * i;
        
        double averageMem =
          (totalMem + [currentMem doubleValue]) / (double)(i + 1);
        
        [avgMem
          setObject: [NSNumber numberWithDouble: averageMem]
          forKey: command];
        }
      }
    }
  
  return avgMem;
  }

// Print top processes by memory.
- (void) printTopProcesses: (NSArray *) processes
  {
  [self.result
    appendAttributedString: [self buildTitle: @"Top Processes by Memory:"]];
  
  NSUInteger count = 0;
  
  ByteCountFormatter * formatter = [[ByteCountFormatter alloc] init];

  for(NSDictionary * process in processes)
    if([self printTopProcess: process formatter: formatter])
      {
      ++count;
            
      if(count >= 5)
        break;
      }

  [self
    setTabs: @[@28, @112]
    forRange: NSMakeRange(0, [self.result length])];
  
  [self.result appendCR];
  
  [formatter release];
  }

// Print a top process.
// Return YES if the process could be printed.
- (BOOL) printTopProcess: (NSDictionary *) process
  formatter: (ByteCountFormatter *) formatter
  {
  NSArray * commands = [process allKeys];
  NSArray * mems = [process allValues];

  if(commands && mems && [commands count] && [mems count])
    {
    NSString * command = [commands objectAtIndex: 0];
    double mem = [[mems objectAtIndex: 0] doubleValue];

    NSString * output =
      [NSString
        stringWithFormat:
          @"\t%-9@\t%@\n",
          [formatter stringFromByteCount: mem],
          command];
      
    if(mem > 1024 * 1024 * 1024)
      [self.result
        appendString: output
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];      
    else
      [self.result appendString: output];
      
    return YES;
    }
    
  return NO;
  }

@end
