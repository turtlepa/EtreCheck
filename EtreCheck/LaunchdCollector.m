/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "LaunchdCollector.h"
#import <ServiceManagement/ServiceManagement.h>
#import "NSMutableAttributedString+Etresoft.h"
#import "SystemInformation.h"
#import "Utilities.h"
#import "NSDictionary+Etresoft.h"

#define kStatus @"status"
#define kHidden @"hidden"
#define kApple @"apple"
#define kFilename @"filename"
#define kExecutable @"executable"
#define kSupportURL @"supporturl"
#define kPlist @"plist"

#define kStatusUnknown @"unknown"
#define kStatusNotLoaded @"notloaded"
#define kStatusLoaded @"loaded"
#define kStatusRunning @"running"
#define kStatusFailed @"failed"
#define kStatusInvalid @"invalid"

@implementation LaunchdCollector

// These need to be shared by all launchd collector objects.
@dynamic launchdStatus;
@dynamic appleLaunchd;
@synthesize showExecutable = myShowExecutable;

// Property accessors to route through a singleton.
- (NSMutableDictionary *) launchdStatus
  {
  return [LaunchdCollector launchdStatus];
  }

- (NSMutableSet *) appleLaunchd
  {
  return [LaunchdCollector appleLaunchd];
  }

// Singleton accessor for launchd status.
+ (NSMutableDictionary *) launchdStatus
  {
  static NSMutableDictionary * dictionary = nil;
  
  static dispatch_once_t onceToken;

  dispatch_once(
    & onceToken,
    ^{
     dictionary = [NSMutableDictionary new];
    });
    
  return dictionary;
  }

// Singleton access for Apple launchd items.
+ (NSMutableSet *) appleLaunchd
  {
  static NSMutableSet * set = nil;
  
  static dispatch_once_t onceToken;

  dispatch_once(
    & onceToken,
    ^{
     set = [NSMutableSet new];
    });
    
  return set;
  }

// Release memory.
+ (void) cleanup
  {
  [[LaunchdCollector launchdStatus] release];
  [[LaunchdCollector appleLaunchd] release];
  }

// Collect the status of all launchd items.
- (void) collect
  {
  if([self.launchdStatus count])
    return;
    
  [self
    updateStatus: NSLocalizedString(@"Checking launchd information", NULL)];
  
  [self collectLaunchdStatus: kSMDomainSystemLaunchd];

  [self collectLaunchdStatus: kSMDomainUserLaunchd];
  
  // Add expected items that ship with the OS.
  [self setupExpectedItems];
    
  dispatch_semaphore_signal(self.complete);
  }

// Collect launchd status for a particular domain.
- (void) collectLaunchdStatus: (CFStringRef) domain
  {
  // Get the last exist result for all jobs in this domain.
  NSArray * jobs = (NSArray *)SMCopyAllJobDictionaries(domain);

  if(!jobs)
    return;

  for(NSDictionary * job in jobs)
    {
    NSString * label = [job objectForKey: @"Label"];
    
    if(label)
      [self.launchdStatus setObject: job forKey: label];
    }
    
  [jobs release];
  }

// Setup launchd items that are expected because they ship with the OS.
- (void) setupExpectedItems
  {
  [self.appleLaunchd addObject: @"org.openbsd.ssh-agent.plist"];
  [self.appleLaunchd addObject: @"bootps.plist"];
  [self.appleLaunchd addObject: @"com.danga.memcached.plist"];
  [self.appleLaunchd addObject: @"com.vix.cron.plist"];
  [self.appleLaunchd addObject: @"exec.plist"];
  [self.appleLaunchd addObject: @"finger.plist"];
  [self.appleLaunchd addObject: @"ftp.plist"];
  [self.appleLaunchd addObject: @"ftp-proxy.plist"];
  [self.appleLaunchd addObject: @"login.plist"];
  [self.appleLaunchd addObject: @"ntalk.plist"];
  [self.appleLaunchd addObject: @"org.apache.httpd.plist"];
  [self.appleLaunchd addObject: @"org.cups.cups-lpd.plist"];
  [self.appleLaunchd addObject: @"org.cups.cupsd.plist"];
  [self.appleLaunchd addObject: @"org.freeradius.radiusd.plist"];
  [self.appleLaunchd addObject: @"org.isc.named.plist"];
  [self.appleLaunchd addObject: @"org.net-snmp.snmpd.plist"];
  [self.appleLaunchd addObject: @"org.ntp.ntpd.plist"];
  [self.appleLaunchd addObject: @"org.openldap.slapd.plist"];
  [self.appleLaunchd addObject: @"org.postfix.master.plist"];
  [self.appleLaunchd addObject: @"org.postgresql.postgres_alt.plist"];
  [self.appleLaunchd addObject: @"shell.plist"];
  [self.appleLaunchd addObject: @"ssh.plist"];
  [self.appleLaunchd addObject: @"telnet.plist"];
  [self.appleLaunchd addObject: @"tftp.plist"];
  [self.appleLaunchd addObject: @"com.apple.appleseed.feedbackhelper"];

  // Snow Leopard.
  [self.appleLaunchd addObject: @"comsat.plist"];
  [self.appleLaunchd addObject: @"distccd.plist"];
  [self.appleLaunchd addObject: @"edu.mit.Kerberos.kadmind.plist"];
  [self.appleLaunchd addObject: @"edu.mit.Kerberos.krb5kdc.plist"];
  [self.appleLaunchd addObject: @"nmbd.plist"];
  [self.appleLaunchd addObject: @"org.amavis.amavisd.plist"];
  [self.appleLaunchd addObject: @"org.amavis.amavisd_cleanup.plist"];
  [self.appleLaunchd addObject: @"org.apache.httpd.plist"];
  [self.appleLaunchd addObject: @"org.x.privileged_startx.plist"];
  [self.appleLaunchd addObject: @"smbd.plist"];
  [self.appleLaunchd addObject: @"edu.mit.Kerberos.CCacheServer.plist"];
  [self.appleLaunchd addObject: @"edu.mit.Kerberos.KerberosAgent.plist"];
  [self.appleLaunchd addObject: @"org.x.startx.plist"];
  }

// Format a list of files.
- (void) formatPropertyListFiles: (NSArray *) paths
  title: (NSString *) title
  {
  NSUInteger start = [self.result length];
  
  NSMutableAttributedString * formattedOutput =
    [self formatPropertyListFiles: paths];

  if(formattedOutput)
    {
    [self.result appendAttributedString: [self buildTitle: title]];

    [self.result appendAttributedString: formattedOutput];

    [self
      setTabs: @[@28, @112, @196]
      forRange: NSMakeRange(start, [self.result length] - start)];

    if(!self.launchdStatus)
      [self.result
        appendString:
          NSLocalizedString(@"\tLaunchd job status not available.\n", NULL)
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];
      
    [self.result appendCR];
    }
  }

// Format a list of files.
- (NSMutableAttributedString *) formatPropertyListFiles: (NSArray *) paths
  {
  NSMutableAttributedString * formattedOutput =
    [NSMutableAttributedString new];

  [formattedOutput autorelease];
  
  BOOL haveOutput = NO;
  
  for(NSString * path in paths)
    if([self formatPropertyListFile: path output: formattedOutput])
      haveOutput = YES;
  
  if(!haveOutput)
    return nil;
    
  return formattedOutput;
  }

// Format property list file.
// Return YES if there was any output.
- (BOOL) formatPropertyListFile: (NSString *) path
  output: (NSMutableAttributedString *) output
  {
  NSString * file = [path lastPathComponent];
  
  // Ignore .DS_Store files.
  if([file isEqualToString: @".DS_Store"])
    return NO;
    
  // Get the status.
  NSDictionary * status = [self collectLaunchdItemStatus: path];
    
  // Apple file get special treatment.
  if([[status objectForKey: kApple] boolValue])
    {
    // I may want to report a failure.
    if([[status objectForKey: kStatus] isEqualToString: kStatusFailed])
      {
      // Should I ignore this failure?
      if([self ignoreFailuresOnFile: file])
        return NO;
      }
    else
      return NO;
    }

  [output appendAttributedString: [self formatPropertyListStatus: status]];
  [output appendString: [status objectForKey: kFilename]];
  [output appendAttributedString: [self formatExtraContent: status]];
  [output appendString: @"\n"];
  
  return YES;
  }

// Collect the status of a launchd item.
- (NSDictionary *) collectLaunchdItemStatus: (NSString *) path
  {
  // I need this.
  NSString * file = [path lastPathComponent];
  
  // Is the file hidden?
  BOOL hidden = [file hasPrefix: @"."];
  
  // Get the properties.
  NSDictionary * plist = [NSDictionary readPropertyList: path];

  // Get the status.
  NSString * jobStatus = [self collectJobStatus: plist];
    
  // Get the executable.
  NSArray * executable = [self collectLaunchdItemExecutable: plist];
  
  // See if the executable is valid.
  if(![self isValidExecutable: executable])
    jobStatus = kStatusInvalid;
    
  return
    @{
      kApple : [NSNumber numberWithBool: [self isAppleFile: file]],
      kFilename : [self sanitizeFilename: file],
      kHidden : [NSNumber numberWithBool: hidden],
      kStatus : jobStatus,
      kExecutable : executable,
      kSupportURL : [self getSupportURL: nil bundleID: path]
    };
  }

// Get the job status.
- (NSString *) collectJobStatus: (NSDictionary *) plist
  {
  NSString * jobStatus = kStatusUnknown;

  if(plist)
    {
    NSString * label = [plist objectForKey: @"Label"];
      
    if(label)
      {
      NSDictionary * status = [self.launchdStatus objectForKey: label];
    
      NSNumber * pid = [status objectForKey: @"PID"];
      NSNumber * lastExitStatus = [status objectForKey: @"LastExitStatus"];

      if(pid)
        jobStatus = kStatusRunning;
      else if([lastExitStatus intValue] != 0)
        jobStatus = kStatusFailed;
      else if(status)
        jobStatus = kStatusLoaded;
      else
        jobStatus = kStatusNotLoaded;
      }
    }
    
  return jobStatus;
  }

// Should I ignore failures?
- (BOOL) ignoreFailuresOnFile: (NSString *) file
  {
  if([file isEqualToString: @"com.apple.xprotectupdater.plist"])
    return YES;
  else if([file isEqualToString: @"com.apple.afpstat.plist"])
    return YES;
  else if([file isEqualToString: @"com.apple.KerberosHelper.LKDCHelper.plist"])
    return YES;
  else if([file isEqualToString: @"com.apple.emond.aslmanager.plist"])
    return YES;
  else if([file isEqualToString: @"com.apple.mrt.uiagent.plist"])
    return YES;

  // Snow Leopard
  else if([file isEqualToString: @"com.apple.suhelperd.plist"])
    return YES;
  else if([file isEqualToString: @"com.apple.Kerberos.renew.plist"])
    return YES;
  
  else if([file isEqualToString: @"org.samba.winbindd.plist"])
    return YES;
    
  return NO;
  }

// Is this an Apple file that I expect to see?
- (BOOL) isAppleFile: (NSString *) file
  {
  if([file hasPrefix: @"com.apple."])
    return YES;
    
  if([self.appleLaunchd containsObject: file])
    return YES;
    
  return NO;
  }

// Make a file name more presentable.
- (NSString *) sanitizeFilename: (NSString *) file
  {
  NSString * prettyFile = file;
  
  // What are you trying to hide?
  if([file hasPrefix: @"."])
    prettyFile =
      [NSString
        stringWithFormat: NSLocalizedString(@"%@ (hidden)", NULL), file];

  // Silly Apple.
  else if([file hasPrefix: @"com.apple.CSConfigDotMacCert-"])
    prettyFile = [self sanitizeMobileMe: file];

  // What are you trying to expose?
  else if([file hasPrefix: @"com.facebook.videochat."])
    prettyFile = [self sanitizeFacebook: file];

  // What are you trying to expose?
  else if([file hasPrefix: @"com.adobe.ARM."])
    prettyFile = @"com.adobe.ARM.[...].plist";

  // I don't want to see it.
  else if([file length] > 76)
    {
    NSString * extension = [file pathExtension];
    
    prettyFile =
      [NSString
        stringWithFormat:
          @"%@...%@", [file substringToIndex: 40], extension];
    }
    
  return prettyFile;
  }

// Apple used to put the user's name into a file name.
- (NSString *) sanitizeMobileMe: (NSString *) file
  {
  NSScanner * scanner = [NSScanner scannerWithString: file];

  BOOL found =
    [scanner
      scanString: @"com.apple.CSConfigDotMacCert-" intoString: NULL];

  if(!found)
    return file;
    
  found = [scanner scanUpToString: @"@" intoString: NULL];

  if(!found)
    return file;
    
  NSString * domain = nil;
  
  found = [scanner scanUpToString: @".com-" intoString: & domain];

  if(!found)
    return file;

  found = [scanner scanString: @".com-" intoString: NULL];

  if(!found)
    return file;
    
  NSString * suffix = nil;

  found = [scanner scanUpToString: @"\n" intoString: & suffix];

  if(!found)
    return file;
    
  return
    [NSString
      stringWithFormat:
        @"com.apple.CSConfigDotMacCert-[...]%@.com-%@", domain, suffix];
  }

/* Facebook puts the users name in a filename too. */
- (NSString *) sanitizeFacebook: (NSString *) file
  {
  NSScanner * scanner = [NSScanner scannerWithString: file];

  BOOL found =
    [scanner
      scanString: @"com.facebook.videochat." intoString: NULL];

  if(!found)
    return file;
    
  [scanner scanUpToString: @".plist" intoString: NULL];

  return
    NSLocalizedString(@"com.facebook.videochat.[redacted].plist", NULL);
  }

// Collect the executable of the launchd item.
- (NSArray *) collectLaunchdItemExecutable: (NSDictionary *) plist
  {
  NSMutableArray * executable = [NSMutableArray array];
  
  if(plist)
    {
    NSString * program = [plist objectForKey: @"Program"];
    
    if(program)
      [executable addObject: program];
      
    NSArray * arguments = [plist objectForKey: @"ProgramArguments"];
    
    if(arguments)
      [executable addObjectsFromArray: arguments];
    }
    
  return executable;
  }

// Is the executable valid?
- (BOOL) isValidExecutable: (NSArray *) executable
  {
  NSString * program = [executable firstObject];
  
  if(program)
    {
    NSDictionary * attributes =
      [[NSFileManager defaultManager]
        attributesOfItemAtPath: program error: NULL];
    
    if(attributes)
      {
      NSUInteger permissions = attributes.filePosixPermissions;
      
      if(permissions & S_IXUSR)
        return YES;
        
      if(permissions & S_IXGRP)
        return YES;

      if(permissions & S_IXOTH)
        return YES;
      }
      //if([[NSFileManager defaultManager] isExecutableFileAtPath: program])
      //  return YES;
    }
    
  return NO;
  }

// Format a status string.
- (NSAttributedString *) formatPropertyListStatus: (NSDictionary *) status
  {
  NSString * statusString = NSLocalizedString(@"[not loaded]", NULL);
  NSColor * color = [[Utilities shared] gray];;
  
  NSString * statusCode = [status objectForKey: kStatus];
  
  if([statusCode isEqualToString: kStatusLoaded])
    {
    statusString = NSLocalizedString(@"[loaded]", NULL);
    color = [[Utilities shared] blue];
    }
  else if([statusCode isEqualToString: kStatusRunning])
    {
    statusString = NSLocalizedString(@"[running]", NULL);
    color = [[Utilities shared] green];
    }
  else if([statusCode isEqualToString: kStatusFailed])
    {
    statusString = NSLocalizedString(@"[failed]", NULL);
    color = [[Utilities shared] red];
    }
  else if([statusCode isEqualToString: kStatusUnknown])
    {
    statusString = NSLocalizedString(@"[unknown]", NULL);
    color = [[Utilities shared] red];
    }
  else if([statusCode isEqualToString: kStatusInvalid])
    {
    statusString = NSLocalizedString(@"[invalid?]", NULL);
    color = [[Utilities shared] red];
    }
  
  NSMutableAttributedString * output =
    [[NSMutableAttributedString alloc] init];
    
  [output
    appendString: [NSString stringWithFormat: @"\t%@\t", statusString]
    attributes:
      [NSDictionary
        dictionaryWithObjectsAndKeys:
          color, NSForegroundColorAttributeName, nil]];
  
  return [output autorelease];
  }

// Include any extra content that may be useful.
- (NSAttributedString *) formatExtraContent: (NSDictionary *) status
  {
  NSMutableAttributedString * extra =
    [[NSMutableAttributedString alloc] init];
  
  // Get the support link.
  if([[status objectForKey: kSupportURL] length])
    {
    [extra appendString: @" "];

    [extra
      appendString: NSLocalizedString(@"Support", NULL)
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
          NSForegroundColorAttributeName : [[Utilities shared] gray],
          NSLinkAttributeName : [status objectForKey: kSupportURL]
        }];
    }
    
  // Show what is being hidden.
  if([[status objectForKey: kHidden] boolValue] || self.showExecutable)
    [extra appendString:
      [NSString
        stringWithFormat:
          @"\n\t\t%@",
          [Utilities
            formatExecutable: [status objectForKey: kExecutable]]]];
    
  return [extra autorelease];
  }

// Try to construct a support URL.
- (NSString *) getSupportURL: (NSString *) name bundleID: (NSString *) path
  {
  NSString * bundleID = [path lastPathComponent];
  
  // If the file is from Apple, the user is already on ASC.
  if([self isAppleFile: bundleID])
    return @"";
    
  // See if I can construct a real web host.
  NSString * host = [self convertBundleIdToHost: bundleID];
  
  if(host)
    {
    // If I seem to have a web host, construct a support URL just for that
    // site.
    NSString * nameParameter =
      [name length]
        ? [NSString stringWithFormat: @"%@+", name]
        : bundleID;

    return
      [NSString
        stringWithFormat:
          @"http://www.google.com/search?q=%@support+site:%@",
          nameParameter, host];
    }
  
  // This file isn't following standard conventions. Look for uninstall
  // instructions.
  return
    [NSString
      stringWithFormat:
        @"http://www.google.com/search?q=%@+uninstall+support", bundleID];
  }

@end
