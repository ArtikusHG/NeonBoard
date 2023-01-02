#include "../Neon.h"

%hook UIImage
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale {
  UIImage *img = %orig;
  if ([bundleIdentifier isEqualToString:@"com.apple.mobilecal"]) return img;
  NSString *path = [%c(Neon) iconPathForBundleID:bundleIdentifier];
  return (path) ? [[[UIImage imageWithContentsOfFile:path] maskedImageWithBlackBackground:NO homescreenIcon:NO] imageOfSize:img.size] : img;
}

%end

%ctor {
  if (kCFCoreFoundationVersionNumber >= 1740.00 && [[[%c(Neon) prefs] objectForKey:@"kGlyphMode"] boolValue]) %init;
}
