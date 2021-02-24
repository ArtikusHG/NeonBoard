// this exists because NeonCore, for example, injects into lots of system processes, including *really* important ones such as lsd
// and it also makes use of NeonEngine. and NeonEngine (well, it used to) has some UIKit methods.
// so, i put the UIKit methods here so that NeonEngine doesn't link against UIKit, therefore not loading it into system daemons which obviously don't need it. memory leaks gone :P

#include "../Neon.h"
// yes, i'm hooking my own class. don't ask.
%hook Neon

UIImage *maskImage;

%new
+ (UIImage *)getMaskImage {
  if (maskImage) return maskImage;
  // apparently, the bundles folder is not considered necessary, and Theme.theme/bundleid should also be parsed.
  for (NSString *theme in [%c(Neon) themes]) {
    for (NSString *format in @[@"/Library/Themes/%@/Bundles/com.apple.mobileicons.framework/", @"/Library/Themes/%@/com.apple.mobileicons.framework/"]) {
      NSString *path = [NSString stringWithFormat:format, theme];
      if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) {
        NSString *maskPath = [%c(Neon) fullPathForImageNamed:@"AppIconMask" atPath:path];
        if (maskPath) {
          maskImage = [UIImage imageWithContentsOfFile:maskPath];
          return maskImage;
        }
      }
    }
  }
  NSBundle *mobileIconsBundle = [NSBundle bundleWithIdentifier:@"com.apple.mobileicons.framework"];
  maskImage = [UIImage imageNamed:@"AppIconMask" inBundle:mobileIconsBundle];
  return maskImage;
}

%new
+ (void)resetMask { maskImage = nil; }

%end

@implementation UIImage (Neon)

- (UIImage *)imageOfSize:(CGSize)size {
  UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
  [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return newImage;
}

- (UIImage *)maskedImageWithBlackBackground:(BOOL)blackBackground homescreenIcon:(BOOL)icon {
  UIImage *maskImage = [%c(Neon) getMaskImage];
  if (maskImage) {
    CGSize size = (icon) ? [%c(Neon) homescreenIconSize] : self.size;
    CGRect imageRect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextClipToMask(UIGraphicsGetCurrentContext(), imageRect, [%c(Neon) getMaskImage].CGImage);
    if (blackBackground) {
      [[UIColor blackColor] setFill];
      UIRectFill(imageRect);
    }
    [self drawInRect:imageRect];
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return finalImage;
  }
  return self;
}

@end
