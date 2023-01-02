#include "../Neon.h"

static NSCache *pathCache = nil;
static NSArray *themes = nil;
static BOOL glyphMode = NO;

static NSString *customPathForPathNoCache(NSString *path) {
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

static NSString *customPathForPath(NSString *path) {
  if (!path) return nil;
  for (NSString *str in @[@"/Library/Themes", @"/NeonCache"]) if ([path rangeOfString:str].location != NSNotFound) return nil;
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

FOUNDATION_EXTERN CGImageSourceRef CGImageSourceCreateWithURL(CFURLRef url, CFDictionaryRef options);
%hookf(CGImageSourceRef, CGImageSourceCreateWithURL, CFURLRef url, CFDictionaryRef options) {
  NSString *path = [(__bridge NSURL *)url path];
  if (glyphMode && [path.lastPathComponent rangeOfString:@"TableIconOutline"].location != NSNotFound) return nil;
  if ([path.pathComponents containsObject:@"VPNPreferences.bundle"]) return %orig;
  NSString *newPath = customPathForPath(path);
  return (newPath) ? %orig(CFBridgingRetain([NSURL fileURLWithPath:newPath]), options) : %orig;
}

FOUNDATION_EXTERN CGImageRef *CGImageSourceCreateWithFile(CFStringRef path, CFDictionaryRef options);
%hookf(CGImageSourceRef, CGImageSourceCreateWithFile, CFStringRef path, CFDictionaryRef options) {
  if (glyphMode && [[(__bridge NSString *)path lastPathComponent] rangeOfString:@"TableIconOutline"].location != NSNotFound) return nil;
  NSString *newPath = customPathForPath((__bridge NSString *)path);
  return (newPath) ? %orig((__bridge CFStringRef)newPath, options) : %orig;
}

%hook NSBundle
- (NSString *)pathForResource:(NSString *)resource ofType:(NSString *)type { NSString *path = %orig; return customPathForPath(path) ?: path; }
- (NSString *)pathForResource:(NSString *)resource ofType:(NSString *)type inDirectory:(NSString *)directory { NSString *path = %orig; return customPathForPath(path) ? : path; }
+ (NSString *)pathForResource:(NSString *)resource ofType:(NSString *)type inDirectory:(NSString *)directory { NSString *path = %orig; return customPathForPath(path) ? : path; }
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
