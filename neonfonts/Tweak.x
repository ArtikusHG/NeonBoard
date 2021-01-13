#include "../Neon.h"

NSCache *fontCache;

NSString *customFontPathForPath(NSString *path) {
  NSString *fontFile = path.lastPathComponent;
  NSString *cachedPath = [fontCache objectForKey:path];
  if (cachedPath) return cachedPath;
  for (NSString *theme in [%c(Neon) themes]) {
    NSString *customPath = [NSString stringWithFormat:@"/Library/Themes/%@/ANEMFontsOverride/%@", theme, fontFile];
    if ([[NSFileManager defaultManager] fileExistsAtPath:customPath]) {
      [fontCache setObject:customPath forKey:path];
      return customPath;
    }
  }
  return nil;
}

NSArray *CGFontCreateFontsWithPath(NSString *path);
%group NormalVersions %hookf(NSArray *, CGFontCreateFontsWithPath, NSString *path) { return %orig(customFontPathForPath(path) ? : path); } %end
%group FrickyStupids %hookf(id, pogchampWOOO, NSString *path, NSString *name) { return %orig(customFontPathForPath(path) ? : path, name); } %end

%ctor {
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon)) return;
  fontCache = [NSCache new];
  %init(NormalVersions);
  if (kCFCoreFoundationVersionNumber >= 1751.108) {
    MSImageRef image = MSGetImageByName("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics");
    %init(FrickyStupids, pogchampWOOO = MSFindSymbol(image, "_CGFontCreateWithPathAndName"));
  }
}
