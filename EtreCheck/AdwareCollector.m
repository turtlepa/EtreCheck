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
@dynamic adwareFiles;

- (NSMutableDictionary *) adwareFiles
  {
  return [[Model model] adwareFiles];
  }

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"adware";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    
    [self loadSignatures];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  self.adwareSignatures = nil;
  
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
  [self
    searchForAdware:
      @"Downlite, VSearch, Conduit, Trovi, MyBrand, Search Protect"];
  [self searchForAdware: @"Genieo, InstallMac"];
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
    
    [[NSFileManager defaultManager]
      removeItemAtPath: @"/tmp/out.bin" error: NULL];
    
    NSDictionary * plist = [Utilities readPropertyListData: plistData];
  
    if(plist)
      {
      NSMutableDictionary * signatures = [NSMutableDictionary dictionary];
  
      NSArray * extensions = [plist objectForKey: @"item1"];
      NSArray * dvctmsp = [plist objectForKey: @"item2"];
      NSArray * gi = [plist objectForKey: @"item3"];
      NSArray * optional = [plist objectForKey: @"item4"];
      
      if(extensions)
        [[Model model] setAdwareExtensions: extensions];

      if(dvctmsp)
        [signatures
          setObject: dvctmsp
          forKey:
            @"Downlite, VSearch, Conduit, Trovi, MyBrand, Search Protect"];

      if(gi)
        [signatures setObject: gi forKey: @"Genieo, InstallMac"];
        
      if(optional)
        [signatures setObject: optional forKey: @"Optional"];

      self.adwareSignatures = signatures;
      }
    }
  }

// Search for existing adware files.
- (void) searchForAdware: (NSString *) adware
  {
  NSArray * files = [self.adwareSignatures objectForKey: adware];
  
  NSMutableArray * foundFiles = [NSMutableArray array];
  
  [foundFiles addObjectsFromArray: [self identifyAdwareFiles: files]];
  
  if([foundFiles count])
    {
    [[Model model] setAdwareFound: YES];

    [self.adwareFiles setObject: foundFiles forKey: adware];
    
    for(NSString * path in foundFiles)
      [[[Model model] adwareFiles]
        setObject: [adware lowercaseString] forKey: path];
    }
  }

// Identify adware files.
- (NSArray *) identifyAdwareFiles: (NSArray *) files
  {
  NSMutableArray * adwareFiles = [NSMutableArray array];
  
  for(NSString * file in files)
    {
    NSString * fullPath = [file stringByExpandingTildeInPath];
    
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
        appendString: [NSString stringWithFormat: @"    %@", adware]
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
