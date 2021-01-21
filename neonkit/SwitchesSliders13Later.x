#ifdef __LP64__

#include <../Neon.h>

UIImage *thumbImage;
BOOL customImageLoaded = NO;

%hook UISwitchModernVisualElement
+ (UIImage *)_modernThumbImageWithColor:(UIColor *)color mask:(unsigned long long)mask traitCollection:(UITraitCollection *)traitCollection {
  if (!customImageLoaded) {
    thumbImage = [UIImage imageNamed:@"UISwitchKnob"];
    customImageLoaded = YES;
  }
  return thumbImage ? : %orig;
}
%end

%hook UISlider
+ (UIImage *)_modernThumbImageWithTraitCollection:(UITraitCollection *)traitCollection tintColor:(UIColor *)tintColor {
  if (!customImageLoaded) {
    thumbImage = [UIImage imageNamed:@"UISwitchKnob"];
    customImageLoaded = YES;
  }
  UIImage *orig = %orig;
  return (thumbImage) ? [[thumbImage imageOfSize:orig.size] resizableImageWithCapInsets:orig.capInsets] : orig;
}
%end

%ctor {
  if (kCFCoreFoundationVersionNumber >= 1665.15) {
    Class sliderClass = (kCFCoreFoundationVersionNumber >= 1751.108) ? %c(_UISlideriOSVisualElement) : %c(UISlider);
    %init(UISlider = sliderClass);
  }
}

#endif
