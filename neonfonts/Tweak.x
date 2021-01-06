#include "../Neon.h"

NSCache *fontCache;

NSArray *CGFontCreateFontsWithPath(NSString *path);
%hookf(NSArray *, CGFontCreateFontsWithPath, NSString *path) {
  NSString *fontFile = path.lastPathComponent;
  NSString *cachedPath = [fontCache objectForKey:path];
  if (cachedPath) return %orig(cachedPath);
  for (NSString *theme in [%c(Neon) themes]) {
    NSString *customPath = [NSString stringWithFormat:@"/Library/Themes/%@/ANEMFontsOverride/%@", theme, fontFile];
    if ([[NSFileManager defaultManager] fileExistsAtPath:customPath]) {
      [fontCache setObject:customPath forKey:path];
      return %orig(customPath);
    }
  }
  return %orig;
}

%ctor {
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon)) return;
  fontCache = [NSCache new];
}
