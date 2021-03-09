// came here to refactor this? full of code structure ideas and innovative logics?
// go away. i tried.

// this is adapted & improved code from WinterBoard. thank you, @saurik.

#include "../Neon.h"
#include "../neonkit/NeonCacheManager.h"

NSArray *CPBitmapCreateImagesFromPath(NSString *path, CFTypeRef *names, void *arg2, void *arg3);

// https://stackoverflow.com/questions/7792622/manual-retain-with-arc
#define AntiARCRetain(...) void *retainedThing = (__bridge_retained void *)__VA_ARGS__; retainedThing = retainedThing

BOOL maskIcons;

%hookf(NSArray *, CPBitmapCreateImagesFromPath, NSString *path, CFTypeRef *names, void *arg2, void *arg3) {
  if (!%orig || %orig.count == 0 || !names) return %orig;
  NSDictionary *indexes;
  NSEnumerator *enumerator;
  if (CFGetTypeID((CFTypeRef) *names) == CFDictionaryGetTypeID()) {
    indexes = (__bridge NSDictionary *)(CFDictionaryRef)names;
    enumerator = [indexes keyEnumerator];
  } else enumerator = [(__bridge NSArray *)*names objectEnumerator];

  NSArray *images = %orig;
  NSMutableArray *copy = [images mutableCopy];
  images = copy;
  NSString *name;
  BOOL isDir;
  [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
  NSString *bundleID = [NSBundle bundleWithPath:(isDir) ? path : path.stringByDeletingLastPathComponent].bundleIdentifier;
  for (NSUInteger index = 0; name = [enumerator nextObject]; index++) {
    UIImage *finalImage;
    UIImage *cachedImage = [%c(NeonCacheManager) getCacheImage:name bundleID:@"NeonSettings"];
    if (cachedImage) finalImage = cachedImage;
    else {
      for (NSString *theme in [%c(Neon) themes]) {
        for (NSString *bundleIdentifier in @[bundleID, @"com.apple.Preferences", @"com.apple.preferences-framework", @"com.apple.preferences-ui-framework"]) {
          NSString *fullPath = [%c(Neon) fullPathForImageNamed:name atPath:[NSString stringWithFormat:@"/Library/Themes/%@/Bundles/%@/", theme, bundleIdentifier]];
          if (fullPath) {
            finalImage = [UIImage imageWithContentsOfFile:fullPath];
            if (maskIcons) finalImage = [finalImage maskedImageWithBlackBackground:NO homescreenIcon:NO];
            CGImageRef originalImage = (__bridge CGImageRef)[copy objectAtIndex:index];
            finalImage = [finalImage imageOfSize:CGSizeMake(CGImageGetWidth(originalImage) / [UIScreen mainScreen].scale, CGImageGetHeight(originalImage) / [UIScreen mainScreen].scale)];
            [%c(NeonCacheManager) storeCacheImage:finalImage name:name bundleID:@"NeonSettings"];
            break;
          }
        }
      }
    }
    if (indexes != nil) index = [[indexes objectForKey:name] intValue];
    if (!finalImage) {
      if (maskIcons) {
        finalImage = [[UIImage imageWithCGImage:(__bridge CGImageRef)[copy objectAtIndex:index] scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp] maskedImageWithBlackBackground:NO homescreenIcon:NO];
        [%c(NeonCacheManager) storeCacheImage:finalImage name:name bundleID:@"NeonSettings"];
      } else continue;
    }
    [copy replaceObjectAtIndex:index withObject:(id)[finalImage CGImage]];
  }
  AntiARCRetain(images);
  return images;
}

%ctor {
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon) && ![%c(Neon) themes]) return;
  maskIcons = [[[%c(Neon) prefs] objectForKey:@"kMaskSettings"] boolValue];
  %init;
}
