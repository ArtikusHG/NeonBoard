#include "../Neon.h"
#include <notify.h>

@interface _LSBoundIconInfo
@property (nonatomic, copy) NSString *applicationIdentifier;
@end

@interface CUICatalog : NSObject
@property (nonatomic, copy) NSString *bundleID;
@end

@interface ISAssetCatalogResource : NSObject
@property (readonly) CUICatalog *catalog;
@property (readonly) NSString *imageName;
@end

@interface IFBundle : NSObject
@property (readonly, copy) NSString *bundleID;
@property (readonly, copy) NSURL *bundleURL;
@end

static NSMutableDictionary *_kNeonURLBundleIDMap = nil;

%group Themes15

%hook CUICatalog

%property (nonatomic, copy) NSString *bundleID;

- (id)initWithName:(id)arg1 fromBundle:(NSBundle *)arg2 error:(id*)arg3 {
  self.bundleID = arg2.bundleIdentifier;
  return %orig;
}

- (id)initWithURL:(NSURL *)arg1 error:(id*)arg2 {
  for (NSString *bundlePath in _kNeonURLBundleIDMap) {
    if ([arg1.path hasPrefix:bundlePath]) {
      self.bundleID = _kNeonURLBundleIDMap[bundlePath];
      break;
    }
  }
  return %orig;
}

%end

%hook ISAssetCatalogResource

- (id)imageForSize:(CGSize)arg1 scale:(double)arg2 {
  NSString *bundleID = self.catalog.bundleID;
  if (!bundleID)
    return %orig;
  NSString *path = [%c(Neon) iconPathForBundleID:bundleID];
  if (!path)
    return %orig;
  return [UIImage imageWithContentsOfFile:path];
}

%end

%hook IFBundle

- (NSArray <NSURL *> *)URLsForResourcesWithExtension:(NSString *)arg1 subdirectory:(NSString *)arg2 {
  if (self.bundleURL)
    _kNeonURLBundleIDMap[self.bundleURL.path] = self.bundleID;
  %log; return %orig;  // These icons will not be themed.
}

- (NSURL *)URLForResource:(NSString *)arg1 withExtension:(NSString *)arg2 subdirectory:(NSString *)arg3 {
  %log;
  if (self.bundleURL)
    _kNeonURLBundleIDMap[self.bundleURL.path] = self.bundleID;
  NSString *path = [%c(Neon) iconPathForBundleID:self.bundleID];
  if (!path)
    return %orig;
  if ([arg2 isEqualToString:@"png"])
    return [NSURL fileURLWithPath:path];
  return %orig;
}

%end

%end

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
  int token;
  notify_register_dispatch("com.artikus.neonboard.reload", &token, dispatch_get_main_queue(), ^(int token) {
    if ([[[NSProcessInfo processInfo] arguments][0] isEqualToString:@"/System/Library/CoreServices/iconservicesagent"])
    {
      [[NSFileManager defaultManager] removeItemAtPath:@"/var/containers/Shared/SystemGroup/systemgroup.com.apple.lsd.iconscache/Library/Caches/com.apple.IconsCache" error:nil];
      exit(1);
    }
  });
  _kNeonURLBundleIDMap = [NSMutableDictionary new];
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon)) return;
  if ([%c(Neon) themes] && [%c(Neon) themes].count > 0) {
    /**/ if (kCFCoreFoundationVersionNumber >= 1854.00) %init(Themes15);
    else if (kCFCoreFoundationVersionNumber >= 1665.15) %init(Themes13);
    else if (kCFCoreFoundationVersionNumber >= 1443.00) %init(Themes_1112);
    else %init(ThemesOlder);
    if ([[%c(Neon) prefs] valueForKey:@"kGlyphMode"] && [[[%c(Neon) prefs] valueForKey:@"kGlyphMode"] boolValue])
      %init(GlyphMode);
  }
}
