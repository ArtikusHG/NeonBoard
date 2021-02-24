#include "../Neon.h"

%hook UIImage
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale {
  if ([bundleIdentifier isEqualToString:@"com.apple.mobilecal"]) return %orig;
  NSString *path = [%c(Neon) iconPathForBundleID:bundleIdentifier];
  return (path) ? [[[UIImage imageWithContentsOfFile:path] maskedImageWithBlackBackground:NO homescreenIcon:NO] imageOfSize:%orig.size] : %orig;
}

%end

%ctor {
  if (kCFCoreFoundationVersionNumber >= 1740.00 && [[[%c(Neon) prefs] objectForKey:@"kGlyphMode"] boolValue]) %init;
}
