#include "../Neon.h"

@interface _LSBoundIconInfo
@property (nonatomic, copy) NSString *applicationIdentifier;
@end

%group Themes13

%hook _LSBoundIconInfo

// hooking setter makes icons in safari "open in app" banner blank
- (NSURL *)resourcesDirectoryURL {
  NSString *path = [%c(Neon) iconPathForBundleID:self.applicationIdentifier];
  return (path) ? [NSURL fileURLWithPath:path.stringByDeletingLastPathComponent] : %orig;
}

- (NSDictionary *)bundleIconsDictionary {
  NSString *path = [%c(Neon) iconPathForBundleID:self.applicationIdentifier].lastPathComponent;
  return (path) ? @{ @"CFBundlePrimaryIcon" : @{ @"CFBundleIconFiles" : @[path] } } : %orig;
}

%end

%end

%group Themes_1112

%hook LSApplicationProxy

// ios 11 & 12
- (NSURL *)_boundResourcesDirectoryURL {
  NSString *path = [%c(Neon) iconPathForBundleID:self._boundApplicationIdentifier];
  return (path) ? [NSURL fileURLWithPath:path.stringByDeletingLastPathComponent] : %orig;
}

- (NSDictionary *)iconsDictionary {
  NSString *path = [%c(Neon) iconPathForBundleID:self._boundApplicationIdentifier].lastPathComponent;
  return (path) ? @{ @"CFBundlePrimaryIcon" : @{ @"CFBundleIconFiles" : @[path] } } : %orig;
}

%end

%end

%group ThemesOlder

%hook LSApplicationProxy

// ios 10
- (NSURL *)boundResourcesDirectoryURL {
  //[[NSString stringWithFormat:@"%@\n%@", [NSString stringWithContentsOfFile:@"/var/mobile/a" encoding:NSUTF8StringEncoding error:nil], self.boundApplicationIdentifier] writeToFile:@"/var/mobile/a" atomically:YES encoding:NSUTF8StringEncoding error:nil];
  NSString *path = [%c(Neon) iconPathForBundleID:self.boundApplicationIdentifier];
  return (path) ? [NSURL fileURLWithPath:path.stringByDeletingLastPathComponent] : %orig;
}

- (NSURL *)resourcesDirectoryURL {
  NSString *path = [%c(Neon) iconPathForBundleID:self.boundApplicationIdentifier];
  return (path) ? [NSURL fileURLWithPath:path.stringByDeletingLastPathComponent] : %orig;
}

// is actually _LSLazyPropertyList of same format but who cares lol it works
- (NSDictionary *)iconsDictionary {
  NSString *path = [%c(Neon) iconPathForBundleID:self.boundApplicationIdentifier].lastPathComponent;
  return (path) ? @{ @"CFBundlePrimaryIcon" : @{ @"CFBundleIconFiles" : @[path] }, @"UIPrerenderedIcon" : @YES } : %orig;
}

- (NSDictionary *)boundIconsDictionary {
  NSString *path = [%c(Neon) iconPathForBundleID:self.boundApplicationIdentifier].lastPathComponent;
  return (path) ? @{ @"CFBundlePrimaryIcon" : @{ @"CFBundleIconFiles" : @[path] }, @"UIPrerenderedIcon" : @YES } : %orig;
}

%end

%end

%group GlyphMode

// Remove black bg, iOS 13+
%hook ISIconCacheClient
- (NSData *)iconBitmapDataWithResourceLocator:(id)locator variant:(int)variant options:(int)options {
  return %orig(locator, variant, 8);
}
%end

// iOS 10.3 - 12
%hook LSApplicationProxy

- (NSData *)iconDataForVariant:(int)variant preferredIconName:(NSString *)iconName withOptions:(int)options {
  return %orig(variant, iconName, 8);
}

%end

%end

%ctor {
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon)) return;

  if ([%c(Neon) themes] && [%c(Neon) themes].count > 0) {
    if (kCFCoreFoundationVersionNumber >= 1665.15) %init(Themes13);
    else if (kCFCoreFoundationVersionNumber >= 1443.00) %init(Themes_1112)
      else %init(ThemesOlder);
    if ([[%c(Neon) prefs] valueForKey:@"kGlyphMode"] && [[[%c(Neon) prefs] valueForKey:@"kGlyphMode"] boolValue]) %init(GlyphMode);
  }
}
