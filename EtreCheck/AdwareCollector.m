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
  [self collectAdwareExtensions];
  [self collectConduit];
  [self collectDownlite];
  [self collectGeneio];
  }

// Collect known adware extensions.
- (void) collectAdwareExtensions
  {
  NSArray * extensions =
    [NSArray arrayWithObjects:
      @"Amazon Shopping Assistant by Spigot Inc.",
      @"Ebay Shopping Assistant by Spigot Inc.",
      @"Searchme by Spigot, Inc.",
      @"Slick Savings by Spigot Inc.",
      @"GoPhoto.It",
      @"Omnibar",
      nil];
    
  for(NSString * extension in extensions)
    [[[Model model] adwareFiles]
      setObject: @"adwareextensions" forKey: extension];
  }

// Collect known Downlite files.
- (void) collectDownlite
  {
  NSArray * files =
    [NSArray arrayWithObjects:
      @"/Library/Application Support/VSearch",
      @"/Library/LaunchAgents/com.vsearch.agent.plist",
      @"/Library/LaunchDaemons/com.vsearch.daemon.plist",
      @"/Library/LaunchDaemons/com.vsearch.helper.plist",
      @"/Library/LaunchDaemons/Jack.plist",
      @"/Library/PrivilegedHelperTools/Jack",
      @"/Library/Frameworks/VSearch.framework",
      nil];
    
  [self searchForAdware: @"Downlite" files: files];
  }

// Collect known Conduit files.
- (void) collectConduit
  {
  NSArray * files =
    [NSArray arrayWithObjects:
      @"/Applications/SearchProtect.app",
      @"/Library/LaunchAgents/com.conduit.loader.agent.plist",
      @"/Library/LaunchDaemons/com.perion.searchprotectd.plst",
      @"/Library/Application Support/SIMBL/Plugins/CT2285220.bundle",
      @"/Library/Internet Plug-Ins/ConduitNPAPIPlugin.plugin",
      @"/Library/Internet Plug-Ins/TroviNPAPIPlugin.plugin",
      @"/Library/InputManagers/CTLoader",
      @"/Library/Application Support/Conduit",
      @"/Conduit",
      @"/Trovi",
      nil];

  [self searchForAdware: @"Conduit" files: files];
  }

// Collect known Geneio files.
- (void) collectGeneio
  {
  NSArray * files =
    [NSArray arrayWithObjects:
      @"/Applications/Geneio",
      @"/Applications/InstallMac",
      @"/Applications/Uninstall Genieo",
      @"/Applications/Uninstall IM Completer.app",
      @"/Library/LaunchAgents/com.genieo.completer.download.plist",
      @"/Library/LaunchAgents/com.genieo.completer.update.plist",
      @"/Library/LaunchAgents/com.genieoinnovation.macextension.plist",
      @"/Library/LaunchAgents/com.genieoinnovation.macextension.client.plist",
      @"/Library/LaunchAgents/com.genieo.engine.plist",
      @"/Library/LaunchAgents/com.genieo.completer.update.plist",
      @"/Library/LaunchDaemons/com.genieoinnovation.macextension.client.plist",
      @"/Library/PrivilegedHelperTools/com.genieoinnovation.macextension.client",
      @"/usr/lib/libgenkit.dylib",
      @"/usr/lib/libgenkitsa.dylib",
      @"/usr/lib/libimckit.dylib",
      @"/usr/lib/libimckitsa.dylib",
      @"/Preferences/com.apple.genieo.global.settings.plist",
      @"/SavedState/com.genie.RemoveGenieoMac.savedState",
      @"/Library/Application Support/Genieo",
      @"/Library/Application Support/com.genieoinnovation.Installer",
      @"/Library/Frameworks/GenieoExtra.framework",
      nil];

  [self searchForAdware: @"Geneio" files: files];
  }

// Search for existing adware files.
- (void) searchForAdware: (NSString *) adware files: (NSArray *) files
  {
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
