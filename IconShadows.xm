#include "Neon.h"

NSString *shadowPath;

@interface SBIconView : UIView
@property (nonatomic, retain) CALayer *shadowLayer;
- (void)neon_setupShadow;
@end

%hook SBIconView

%property (nonatomic, retain) CALayer *shadowLayer;

%new
- (void)neon_setupShadow {
  UIImage *shadowImage = [UIImage imageWithContentsOfFile:shadowPath];
  // TODO FIX SCALING
  self.shadowLayer = [CALayer layer];
  self.shadowLayer.frame = CGRectMake(0, 0, shadowImage.size.width, shadowImage.size.height);
  self.shadowLayer.position = CGPointMake(self.layer.bounds.size.width / 2, self.layer.bounds.size.width / 2);
  self.shadowLayer.contents = (id)shadowImage.CGImage;
  [self.layer insertSublayer:self.shadowLayer atIndex:0];
}

// 13+
- (instancetype)initWithConfigurationOptions:(NSUInteger)options listLayoutProvider:(id)provider {
  if (options != 0) return %orig;
  self = %orig;
  // check if it's SBIconView because on iOS 14 in the app library there's SBHLibraryCategoryPodIconView and we don't want the shadows there
  if ([NSStringFromClass([self class]) isEqualToString:@"SBIconView"]) [self neon_setupShadow];
  return self;
}
// 9 - 12
- (instancetype)initWithContentType:(unsigned long long)contentType {
  if (contentType != 0) return %orig;
  self = %orig;
  [self neon_setupShadow];
  return self;
}
// 7 - 8
- (instancetype)initWithDefaultSize {
  self = %orig;
  [self neon_setupShadow];
  return self;
}

// YES I KNOW NO I DONT CARE LEAVE ME ALONE
// seriously, i tried didMoveToWindow, didMoveToSuperview, etc., doesnt work :/ otherwise the shadow layer is sometimes on *top* of icons
// its just that i remember how i got roasted on discord because neonboard hooked layoutSubviews..... in a one-year-old build..... and tbh i dont care, it works and doesnt even kill performance
- (void)layoutSubviews {
  %orig;
  [self.shadowLayer removeFromSuperlayer];
  [self.layer insertSublayer:self.shadowLayer atIndex:0];
}

%end

%ctor {
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon)) return;

  for (NSString *prefix in [%c(Neon) iconEffectDevicePrefixes]) {
    NSString *shadowName = [prefix stringByAppendingString:@"Shadow"];
    for (NSString *theme in [%c(Neon) themes]) {
      NSString *path = [NSString stringWithFormat:@"/Library/Themes/%@/AnemoneEffects/", theme];
      shadowPath = [%c(Neon) fullPathForImageNamed:shadowName atPath:path];
      if (shadowPath) {
        %init;
        break;
      }
    }
  }
}
