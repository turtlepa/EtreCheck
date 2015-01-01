/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "CPUUsageCollector.h"
#import "NSMutableAttributedString+Etresoft.h"

// Collect information about CPU usage.
@implementation CPUUsageCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"cpu";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self updateStatus: NSLocalizedString(@"Sampling processes for CPU", NULL)];

  // Collect the average CPU usage for all processes (5 times).
  NSDictionary * avgCPU = [self collectAverageCPU];
  
  // Sort the result by average value.
  NSArray * processesCPU = [self sortProcesses: avgCPU];
  
  // Print the top processes.
  [self printTopProcesses: processesCPU];
  
  [self.result appendCR];
    
  dispatch_semaphore_signal(self.complete);
  }

// Collect the average CPU usage of all processes.
- (NSDictionary *) collectAverageCPU
  {
  NSMutableDictionary * avgCPU = [NSMutableDictionary dictionary];
  
  for(NSUInteger i = 0; i < 5; ++i)
    {
    usleep(500000);
    
    NSDictionary * current = [self collectProcesses];
    
    for(NSString * command in current)
      {
      NSNumber * currentCPU =
        [[current objectForKey: command] objectForKey: @"cpu"];
      NSNumber * previousCPU = [avgCPU objectForKey: command];
      
      if(!previousCPU)
        [avgCPU setObject: currentCPU forKey: command];
      else if(previousCPU && currentCPU)
        {
        double totalCPU = [previousCPU doubleValue] * i;
        
        double averageCPU =
          (totalCPU + [currentCPU doubleValue]) / (double)(i + 1);
        
        [avgCPU
          setObject: [NSNumber numberWithDouble: averageCPU]
          forKey: command];
        }
      }
    }
  
  return avgCPU;
  }

// Print top processes by CPU.
- (void) printTopProcesses: (NSArray *) processes
  {
  [self.result
    appendAttributedString: [self buildTitle]];
  
  NSUInteger count = 0;
  
  for(NSDictionary * process in processes)
    {
    NSArray * commands = [process allKeys];
    NSArray * cpus = [process allValues];

    if(commands && cpus && [commands count] && [cpus count])
      {
      NSString * command = [commands objectAtIndex: 0];
      double cpu = [[cpus objectAtIndex: 0] doubleValue];

      NSString * output =
        [NSString stringWithFormat: @"\t%6.0lf%%\t%@\n", cpu, command];
        
      if(cpu > 50.0)
        [self.result
          appendString: output
          attributes:
            [NSDictionary
              dictionaryWithObjectsAndKeys:
                [NSColor redColor], NSForegroundColorAttributeName, nil]];      
      else
        [self.result appendString: output];
            
      ++count;
            
      if(cpu == 0.0)
        count = 10;
      
      if(count >= 5)
        break;
      }
    }
  }

@end
