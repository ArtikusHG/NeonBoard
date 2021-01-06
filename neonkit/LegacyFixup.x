#include "../Neon.h"

// iOS 7 - ????? idk tbh. "it just works".
%group GlyphModeLegacy
%hook UIImage
+ (UIImage *)_iconForResourceProxy:(LSApplicationProxy *)proxy variant:(int)variant variantsScale:(CGFloat)scale {
  if (![%c(Neon) iconPathForBundleID:proxy.boundApplicationIdentifier]) return %orig;
  return [%orig(proxy, 25, scale) imageOfSize:%orig.size];
}

%end
%end

%ctor {
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon)) return;
  if (kCFCoreFoundationVersionNumber <= 1348.22 && [[[%c(Neon) prefs] valueForKey:@"kGlyphMode"] boolValue]) %init(GlyphModeLegacy);
}
