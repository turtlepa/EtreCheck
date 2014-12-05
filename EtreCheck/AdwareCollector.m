/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "AdwareCollector.h"
#import "Model.h"
#import "DiagnosticEvent.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"

// Collect information about adware.
@implementation AdwareCollector

@synthesize adwareSignatures = myAdwareSignatures;
@synthesize adwareFiles = myAdwareFiles;

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"adware";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    
    myAdwareFiles = [NSMutableDictionary new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [myAdwareFiles release];
  
  [super dealloc];
  }

// Perform the collection.
- (void) collect
  {
  [self updateStatus: NSLocalizedString(@"Checking for adware", NULL)];

  [self collectAdware];
  
  [self printAdware];
  
  dispatch_semaphore_signal(self.complete);
  }

// Collect adware.
- (void) collectAdware
  {
  [self loadSignatures];
  
  [self searchForAdware: @"Downlite"];
  [self searchForAdware: @"Conduit"];
  [self searchForAdware: @"Geneio"];
  }

// Load signatures from an obfuscated list of signatures.
- (void) loadSignatures
  {
  NSString * signaturePath =
    [[NSBundle mainBundle] pathForResource: @"adware" ofType: @"plist"];
    
  NSData * partialData = [NSData dataWithContentsOfFile: signaturePath];
  
  if(partialData)
    {
    NSMutableData * plistGzipData = [NSMutableData data];
    
    char buf[] = { 0x1F, 0x8B, 0x08 };
    
    [plistGzipData appendBytes: buf length: 3];
    [plistGzipData appendData: partialData];
    
    [plistGzipData writeToFile: @"/tmp/out.bin" atomically: YES];
    
    NSData * plistData = [Utilities ungzip: plistGzipData];
    
    NSDictionary * plist = [Utilities readPropertyListData: plistData];
  
    if(plist)
      {
      NSMutableDictionary * signatures = [NSMutableDictionary dictionary];
  
      NSArray * extensions = [plist objectForKey: @"item1"];
      NSArray * downlite = [plist objectForKey: @"item2"];
      NSArray * conduit = [plist objectForKey: @"item3"];
      NSArray * geneio = [plist objectForKey: @"item4"];
      
      if(extensions)
        [[Model model] setAdwareExtensions: extensions];

      if(downlite)
        [signatures setObject: downlite forKey: @"Downlite"];

      if(conduit)
        [signatures setObject: conduit forKey: @"Conduit"];

      if(geneio)
        [signatures setObject: geneio forKey: @"Geneio"];
        
      self.adwareSignatures = [signatures copy];
      }
    }
  }

// Search for existing adware files.
- (void) searchForAdware: (NSString *) adware
  {
  NSArray * files = [self.adwareSignatures objectForKey: adware];
  
  NSMutableArray * foundFiles = [NSMutableArray array];
  
  [foundFiles
    addObjectsFromArray: [self searchForDomainAdwareFiles: files]];
  [foundFiles
    addObjectsFromArray: [self searchForSystemDomainAdwareFiles: files]];
  [foundFiles
    addObjectsFromArray: [self searchForUserDomainAdwareFiles: files]];
  
  if([foundFiles count])
    {
    [self.adwareFiles setObject: foundFiles forKey: adware];
    
    for(NSString * path in foundFiles)
      [[[Model model] adwareFiles]
        setObject: [adware lowercaseString] forKey: path];
    }
  }

// Search for existing adware files.
- (NSArray *) searchForDomainAdwareFiles: (NSArray *) files
  {
  return [self identifyAdwareFiles: files relativeTo: @""];
  }

// Search for existing adware files in /System.
- (NSArray *) searchForSystemDomainAdwareFiles: (NSArray *) files
  {
  return [self identifyAdwareFiles: files relativeTo: @"/System"];
  }

// Search for existing adware files in ~
- (NSArray *) searchForUserDomainAdwareFiles: (NSArray *) files
  {
  return [self identifyAdwareFiles: files relativeTo: NSHomeDirectory()];
  }

// Identify adware files.
- (NSArray *) identifyAdwareFiles: (NSArray *) files
  relativeTo: (NSString *) base
  {
  NSMutableArray * adwareFiles = [NSMutableArray array];
  
  for(NSString * file in files)
    {
    NSString * fullPath = [base stringByAppendingPathComponent: file];
    
    bool exists =
      [[NSFileManager defaultManager] fileExistsAtPath: fullPath];
      
    if(exists)
      [adwareFiles addObject: fullPath];
    }
    
  return adwareFiles;
  }

// Print any adware found.
- (void) printAdware
  {
  if([self.adwareFiles count])
    {
    [self.result appendAttributedString: [self buildTitle]];
    
    for(NSString * adware in self.adwareFiles)
      {
      [self.result
        appendString: [NSString stringWithFormat: @"\t%@", adware]
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
      
      NSAttributedString * removeLink =
        [self generateRemoveAdwareLink: adware];

      if(removeLink)
        {
        [self.result appendAttributedString: removeLink];
        [self.result appendString: @"\n"];
        }
      }
      
    [self.result appendCR];
    }
  }
  
@end
