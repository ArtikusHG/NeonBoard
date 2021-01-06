#include <UIKit/UIKit.h>
#include "../Neon.h"

NSString *underlayPath;
UIImage *underlayImage;
NSString *overlayPath;
UIImage *overlayImage;

@implementation NeonRenderService

+ (void)loadPrefs {
  for (NSString *prefix in [%c(Neon) iconEffectDevicePrefixes]) {
    NSString *underlayName = [prefix stringByAppendingString:@"Underlay"];
    for (NSString *theme in [%c(Neon) themes]) {
      NSString *path = [NSString stringWithFormat:@"/Library/Themes/%@/AnemoneEffects/", theme];
      underlayPath = [%c(Neon) fullPathForImageNamed:underlayName atPath:path];
      if (underlayPath) break;
    }
    NSString *overlayName = [prefix stringByAppendingString:@"Overlay"];
    for (NSString *theme in [%c(Neon) themes]) {
      NSString *path = [NSString stringWithFormat:@"/Library/Themes/%@/AnemoneEffects/", theme];
      overlayPath = [%c(Neon) fullPathForImageNamed:overlayName atPath:path];
      if (overlayPath) break;
    }
  }
}

+ (void)setupImages {
  if (!underlayImage) underlayImage = [UIImage imageWithContentsOfFile:underlayPath];
  if (!overlayImage) overlayImage = [UIImage imageWithContentsOfFile:overlayPath];
}

+ (void)resetPrefs {
  underlayPath = nil;
  overlayPath = nil;
  underlayImage = nil;
  overlayImage = nil;
}

+ (UIImage *)underlay {
  if ([UIScreen screens] && [UIScreen screens].count != 0) [self setupImages];
  return underlayImage;
}
// not "overlay" cuz apparently its system reserved (https://twitter.com/ArtikusHG/status/1308810859381174272)
+ (UIImage *)overlayImage {
  if ([UIScreen screens] && [UIScreen screens].count != 0) [self setupImages];
  return overlayImage;
}

+ (void)renderIconWithApplicationProxy:(LSApplicationProxy *)proxy {
  if (![UIScreen screens] || [UIScreen screens].count == 0) return;
  [self setupImages];
  UIImage *icon;
  if (kCFCoreFoundationVersionNumber >= 1443) icon = [UIImage _iconForResourceProxy:proxy variant:32 options:8 variantsScale:[UIScreen mainScreen].scale];
  else icon = [UIImage _applicationIconImageForBundleIdentifier:proxy.applicationIdentifier format:2 scale:[UIScreen mainScreen].scale];
  if (!icon) return;
  UIGraphicsBeginImageContextWithOptions(icon.size, NO, icon.scale);
  if ([[[%c(Neon) prefs] objectForKey:@"kMaskRendered"] boolValue])
    CGContextClipToMask(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, icon.size.width, icon.size.height), [%c(Neon) getMaskImage].CGImage);
  if (underlayImage) [underlayImage drawInRect:CGRectMake(0, 0, icon.size.width, icon.size.height)];
  [icon drawInRect:CGRectMake(0, 0, icon.size.width, icon.size.height)];
  if (overlayImage) [overlayImage drawInRect:CGRectMake(0, 0, icon.size.width, icon.size.height)];
  UIImage *final = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  [UIImagePNGRepresentation(final) writeToFile:[NSString stringWithFormat:@"%@/%@.png", [%c(Neon) renderDir], proxy.applicationIdentifier] atomically:YES];
}

@end

%ctor {
  [NeonRenderService loadPrefs];
  // any UIImage code crashes if [UIScreen mainScreen] is not yet loaded; it also crashes even when trying to check if mainScreen is nil, so i check the screens array
  //if ([UIScreen screens] && [UIScreen screens].count != 0) [NeonRenderService setupImages];
}
