#include "../Neon.h"
#include <sys/utsname.h>

@implementation NSDictionary (Neon)
+ (NSDictionary *)dictionaryWithFile:(NSString *)path {
  if (@available(iOS 11, *)) return [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
  return [NSDictionary dictionaryWithContentsOfFile:path];
}
- (void)writeToPath:(NSString *)path {
  if (@available(iOS 11, *)) [self writeToURL:[NSURL fileURLWithPath:path] error:nil];
  else [self writeToFile:path atomically:YES];
}
@end

@implementation NSArray (Neon)
+ (NSArray *)arrayWithFile:(NSString *)path {
  if (@available(iOS 11, *)) return [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
  return [NSArray arrayWithContentsOfFile:path];
}
- (void)writeToPath:(NSString *)path {
  if (@available(iOS 11, *)) [self writeToURL:[NSURL fileURLWithPath:path] error:nil];
  else [self writeToFile:path atomically:YES];
}
@end

NSArray *themes;
NSDictionary *prefs;
NSDictionary *overrideThemes;

@implementation Neon

+ (NSArray *)themes { return themes; }
+ (NSDictionary *)prefs { return prefs; }
+ (NSDictionary *)overrideThemes { return overrideThemes; }

+ (NSString *)renderDir {
  //return (kCFCoreFoundationVersionNumber >= 1348) ? @"/Library/Themes/NeonCache/IconRender" : @"/var/mobile/Library/Caches/NeonCache/IconRender";
  //NSString *docs = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] path];
  //return [docs stringByAppendingPathComponent:@"NeonRenderCache"];
  // so i added this because the documents wasnt working. it started working. then i brought documents back. it also started working. weirdchamp? well, at least it works....
  //return @"/Library/Themes/NeonRenderCache";
  return (kCFCoreFoundationVersionNumber >= 1348.00) ? @"/Library/Themes/.NeonRenderCache" : @"/var/mobile/Documents/NeonRenderCache";
}

CFPropertyListRef MGCopyAnswer(CFStringRef property);

+ (NSNumber *)deviceScale {
  return (__bridge NSNumber *)MGCopyAnswer(CFSTR("main-screen-scale"));
}

+ (NSString *)deviceModel {
  struct utsname systemInfo;
  uname(&systemInfo);
  return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

+ (BOOL)deviceIsIpad { return [[self deviceModel] rangeOfString:@"iPad"].location != NSNotFound; }
+ (BOOL)deviceIsIpadPro { return ([(__bridge NSNumber *)MGCopyAnswer(CFSTR("main-screen-height")) intValue] == 2732); }

+ (NSArray *)iconEffectDevicePrefixes {
  if ([self deviceIsIpad]) {
    if ([self deviceIsIpadPro]) return @[@"iPadPro", @"iPad"];
    return @[@"iPad"];
  }
  return @[@"iPhone"];
}

+ (NSArray *)potentialFilenamesForName:(NSString *)name deviceString:(NSString *)device scale:(NSInteger)scale {
  NSString *scaleString = [@[@"", @"@2x", @"@3x"] objectAtIndex:scale - 1];
  NSMutableArray *potentialFilenames = [NSMutableArray new];
  [potentialFilenames addObject:[NSString stringWithFormat:@"%@%@%@.png", name, device, scaleString]];
  if (scaleString.length > 0) [potentialFilenames addObject:[NSString stringWithFormat:@"%@%@%@.png", name, scaleString, device]];
  [potentialFilenames addObject:[NSString stringWithFormat:@"%@%@.png", name, scaleString]];
  return potentialFilenames;
}

+ (NSMutableArray *)potentialFilenamesForName:(NSString *)name {
  NSMutableArray *potentialFilenames = [NSMutableArray new];
  NSString *device = ([self deviceIsIpad]) ? @"~ipad" : @"~iphone";
  NSInteger scale = [[self deviceScale] integerValue];
  NSMutableArray *numericScales = [NSMutableArray arrayWithObjects:@1, @2, @3, nil];
  // remove the native scale of the device and insert to beginning so that it's priority in the for loop
  [numericScales removeObject:[NSNumber numberWithInteger:scale]];
  [numericScales insertObject:[NSNumber numberWithInteger:scale] atIndex:0];
  for (NSNumber *loopScale in numericScales) [potentialFilenames addObjectsFromArray:[self potentialFilenamesForName:name deviceString:device scale:[loopScale integerValue]]];
    return potentialFilenames;
}

// Usage: fullPathForImageNamed:@"SBBadgeBG" atPath:@"/Library/Themes/Viola Badges.theme/Bundles/com.apple.springboard/" (last symbol of basePath should be a slash (/)!)
+ (NSString *)fullPathForImageNamed:(NSString *)name atPath:(NSString *)basePath {
  if (!name || !basePath) return nil;
  NSMutableArray *potentialFilenames = [self potentialFilenamesForName:name];
  [potentialFilenames insertObject:[name stringByAppendingString:@"-large.png"] atIndex:0];
  for (NSString *filename in potentialFilenames) {
    NSString *fullFilename = [basePath stringByAppendingString:filename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullFilename isDirectory:nil]) return fullFilename;
  }
  return nil;
}

+ (NSString *)iconPathForBundleID:(NSString *)bundleID {
  if (!bundleID) return nil;
  if (![bundleID isEqualToString:@"com.apple.mobiletimer"]) {
    NSString *renderPath = [NSString stringWithFormat:@"%@/%@.png", [Neon renderDir], bundleID];
    if ([[NSFileManager defaultManager] fileExistsAtPath:renderPath]) return renderPath;
  } else {
    NSString *path = [[%c(Neon) renderDir] stringByAppendingPathComponent:@"NeonStaticClockIcon.png"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) return path;
  }
  NSString *overrideTheme = [overrideThemes objectForKey:bundleID];
  if (overrideTheme) {
    if ([overrideTheme isEqualToString:@"none"]) return nil;
    if ([overrideTheme rangeOfString:@"/"].location != NSNotFound) {
      NSString *theme = [overrideTheme pathComponents][0];
      NSString *app = [overrideTheme pathComponents][1];
      return [self iconPathForBundleID:app fromTheme:theme];
    }
    NSString *path = [self iconPathForBundleID:bundleID fromTheme:overrideTheme];
    if (path) return path;
  }
  for (NSString *theme in themes) {
    NSString *path = [Neon iconPathForBundleID:bundleID fromTheme:theme];
    if (path) return path;
  }
  return nil;
}

// Usage: iconPathForBundleID:@"com.saurik.Cydia" fromTheme:@"Viola.theme"
+ (NSString *)iconPathForBundleID:(NSString *)bundleID fromTheme:(NSString *)theme {
  // Protection against dumbasses (me)
  if (!bundleID || !theme) return nil;
  // Check if theme dir exists
  NSString *themeDir = [NSString stringWithFormat:@"/Library/Themes/%@/IconBundles/", theme];
  if (![[NSFileManager defaultManager] fileExistsAtPath:themeDir isDirectory:nil]) return nil;
  // Return filename (or nil)
  NSString *path = [Neon fullPathForImageNamed:bundleID atPath:themeDir];
  if (!path && [bundleID isEqualToString:@"com.apple.mobiletimer"]) {
    themeDir = [NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.springboard/", theme];
    path = [Neon fullPathForImageNamed:@"ClockIconBackgroundSquare" atPath:themeDir];
  }
  return path;
}

+ (CGSize)homescreenIconSize {
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    if (MAX([[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height) == 1366) return CGSizeMake(83.5, 83.5);
    return CGSizeMake(76, 76);
  }
  return CGSizeMake(60, 60);
}

+ (void)loadPrefs {
  prefs = [NSDictionary dictionaryWithFile:@"/var/mobile/Library/Preferences/com.artikus.neonboardprefs.plist"];
  if (!prefs) return;
  themes = [prefs valueForKey:@"enabledThemes"];
  overrideThemes = [prefs objectForKey:@"overrideThemes"];
}

@end

%ctor {
  if (![[NSFileManager defaultManager] fileExistsAtPath:[%c(Neon) renderDir]])
    [[NSFileManager defaultManager] createDirectoryAtPath:[%c(Neon) renderDir] withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions: @0777} error:nil];
  [Neon loadPrefs];
  if (!prefs || !themes) return;
}
