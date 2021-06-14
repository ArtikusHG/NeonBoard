#include "../Neon.h"

NSCache *pathCache;
NSArray *themes;
BOOL glyphMode;

NSString *customPathForPathNoCache(NSString *path) {
  if (!path) return nil;
  NSString *filename = path.lastPathComponent;
  for (NSString *theme in themes) {
    NSBundle *bundle = [NSBundle bundleWithPath:path.stringByDeletingLastPathComponent];
    if (!bundle || !bundle.bundleIdentifier) bundle = [NSBundle mainBundle];
    NSMutableArray *potentialPaths = [NSMutableArray new];
    [potentialPaths addObject:[NSString stringWithFormat:@"/Library/Themes/%@/Bundles/%@/%@", theme, bundle.bundleIdentifier, filename]];
    [potentialPaths addObject:[NSString stringWithFormat:@"/Library/Themes/%@/%@/%@", theme, bundle.bundleIdentifier, filename]];
    // use com.apple.springboard instead of com.apple.SpringBoardHome and such weird shits
    if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
      [potentialPaths addObject:[NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.springboard/%@/", theme, filename]];
      [potentialPaths addObject:[NSString stringWithFormat:@"/Library/Themes/%@/com.apple.springboard/%@/", theme, filename]];
    }
    // "Folders" folder
    // 1st component is always "/" so from 1
    for (NSInteger i = 1; i < path.pathComponents.count; i++) {
      NSString *newPath = [NSString pathWithComponents:[path.pathComponents subarrayWithRange:NSMakeRange(i, path.pathComponents.count - i)]];
      [potentialPaths addObject:[NSString stringWithFormat:@"/Library/Themes/%@/Folders/%@", theme, newPath]];
      [potentialPaths addObject:[NSString stringWithFormat:@"/Library/Themes/%@/Folders/%@/%@", theme, bundle.bundleIdentifier, newPath]];
    }
    for (NSString *imagePath in potentialPaths) if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) return imagePath;
  }
  if ([path hasPrefix:@"/Applications/Activator.app"] && [filename rangeOfString:@"Icon"].location != NSNotFound) {
    NSString *activatorPath = [NSString stringWithFormat:@"%@/Activator/%@", [%c(Neon) renderDir], filename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:activatorPath]) return activatorPath;
  }
  return nil;
}

NSString *customPathForPath(NSString *path) {
  if (!path) return nil;
  for (NSString *str in @[@"/Library/Themes", @"NeonCache"]) if ([path rangeOfString:str].location != NSNotFound) return nil;
    NSString *cachedPath = [pathCache objectForKey:path];
  if (cachedPath) {
    // check if it exists cuz if someone removes a theme
    if (cachedPath.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:cachedPath]) return cachedPath;
    return nil;
  }
  NSString *customPath = customPathForPathNoCache(path);
  if (customPath) [pathCache setObject:customPath forKey:path];
  else [pathCache setObject:@"" forKey:path];
  return customPath;
}

CGImageSourceRef CGImageSourceCreateWithURL(CFURLRef url, CFDictionaryRef options);
%hookf(CGImageSourceRef, CGImageSourceCreateWithURL, CFURLRef url, NSDictionary *options) {
  NSString *path = [(__bridge NSURL *)url path];
  if (glyphMode && [path.lastPathComponent rangeOfString:@"TableIconOutline"].location != NSNotFound) return nil;
  NSString *newPath = customPathForPath(path);
  return (newPath) ? %orig(CFBridgingRetain([NSURL fileURLWithPath:newPath]), options) : %orig;
}

CGImageRef *CGImageSourceCreateWithFile(NSString *path, NSDictionary *options);
%hookf(CGImageSourceRef, CGImageSourceCreateWithFile, NSString *path, NSDictionary *options) {
  if (glyphMode && [path.lastPathComponent rangeOfString:@"TableIconOutline"].location != NSNotFound) return nil;
  NSString *newPath = customPathForPath(path);
  return (newPath) ? %orig(newPath, options) : %orig;
}

%hook NSBundle
- (NSString *)pathForResource:(NSString *)resource ofType:(NSString *)type { return customPathForPath(%orig) ? : %orig; }
- (NSString *)pathForResource:(NSString *)resource ofType:(NSString *)type inDirectory:(NSString *)directory { return customPathForPath(%orig) ? : %orig; }
+ (NSString *)pathForResource:(NSString *)resource ofType:(NSString *)type inDirectory:(NSString *)directory { return customPathForPath(%orig) ? : %orig; }
%end

%hookf(CFURLRef, CFBundleCopyResourceURL, CFBundleRef bundle, CFStringRef resourceName, CFStringRef resourceType, CFStringRef subDirName) {
  CFURLRef url = %orig;
  NSString *newPath = customPathForPath([(__bridge NSURL *)url path]);
  return (newPath) ? CFBridgingRetain([NSURL fileURLWithPath:newPath]) : url;
}

%ctor {
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon) && ![%c(Neon) themes]) return;
  themes = [%c(Neon) themes];
  glyphMode = [[[%c(Neon) prefs] objectForKey:@"kGlyphMode"] boolValue];
  pathCache = [NSCache new];
  %init;
}
