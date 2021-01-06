// https://github.com/AnemoneTeam/Anemone-OSS

#include "Neon.h"
#include "UIColor+CSSColors.h"

void drawStringInContextWithSettingsDict(NSString *str, CGContextRef ctx, NSDictionary *dict, CGSize imageSize, UIColor *fallbackColor, BOOL forCalendar, UIFont *defaultFont);

NSMutableDictionary *badgeSettings;

@interface SBIconAccessoryImage : UIImage
- (instancetype)initWithImage:(UIImage *)image;
@end

@interface SBIconBadgeView : NSObject
+ (SBIconAccessoryImage *)checkoutImageForText:(NSString *)text font:(UIFont *)origFont highlighted:(BOOL)highlighted;
+ (SBIconAccessoryImage *)customBackgroundImage;
@end

@interface SBHIconAccessoryCountedMapImageTuple : NSObject
- (instancetype)initWithImage:(UIImage *)image countedMapKey:(NSString *)countedMapKey;
@end

id backgroundImage;
id customBackgroundImage() {
  if (!backgroundImage) {
    UIImage *badgeBG = [UIImage imageNamed:@"SBBadgeBG"];
    if (badgeBG) {
      if (kCFCoreFoundationVersionNumber >= 1740) {
        NSString *key = [NSString stringWithFormat:@"SBIconBadgeView.BadgeBackground:%d:%d", (int)badgeBG.size.width, (int)badgeBG.size.height];
        backgroundImage = [[%c(SBHIconAccessoryCountedMapImageTuple) alloc] initWithImage:badgeBG countedMapKey:key];
      } else backgroundImage = [[%c(SBIconAccessoryImage) alloc] initWithImage:badgeBG];
    }
  }
  return backgroundImage;
}

%group BadgeImageHook
%hook SBIconBadgeView
- (SBIconAccessoryImage *)_checkoutBackgroundImage { return customBackgroundImage() ? : %orig; }
+ (SBIconAccessoryImage *)_checkoutBackgroundImage { return customBackgroundImage() ? : %orig; }
- (SBHIconAccessoryCountedMapImageTuple *)_checkoutBackgroundImageTuple { return customBackgroundImage() ? : %orig; }
%end
%end

SBIconAccessoryImage *imageForText(NSString *text, UIFont *font, BOOL highlighted) {
  drawStringInContextWithSettingsDict(text, nil, badgeSettings, CGSizeZero, [UIColor whiteColor], NO, font);
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  if (kCFCoreFoundationVersionNumber >= 1740) {
    // original key: 2:.SFUI-Regular:16.0:0; wtf is the last parameter? its always zero anyway.
    NSString *key = [NSString stringWithFormat:@"%@:%@:%f:0", text, badgeSettings[@"FontName"] ? : font.fontName, font.pointSize];
    return [[%c(SBHIconAccessoryCountedMapImageTuple) alloc] initWithImage:image countedMapKey:key];
  }
  return [[%c(SBIconAccessoryImage) alloc] initWithImage:image];
}

%group BadgeTextHook
%hook SBIconBadgeView
+ (SBIconAccessoryImage *)_checkoutImageForText:(NSString *)text font:(UIFont *)font highlighted:(BOOL)highlighted { return imageForText(text, font, highlighted) ? : %orig; }
+ (SBIconAccessoryImage *)_checkoutImageForText:(NSString *)text highlighted:(BOOL)highlighted { return imageForText(text, nil, highlighted) ? : %orig; }
%end
%end

%ctor {
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon) || ![%c(Neon) prefs]) return;
  %init(BadgeImageHook);

  for (NSString *theme in [%c(Neon) themes]) {
    NSDictionary *themeDict = [NSDictionary dictionaryWithFile:[NSString stringWithFormat:@"/Library/Themes/%@/Info.plist", theme]];
    badgeSettings = [(themeDict[@"BadgeSettings"] ? : themeDict[@"ThemeLib-BadgeSettings"]) mutableCopy];
    if (badgeSettings && badgeSettings.count != 0) break;
  }
  if (!badgeSettings || badgeSettings.count == 0) return;

  if (!badgeSettings[@"FontSize"]) [badgeSettings setObject:@16.0f forKey:@"FontSize"];
  [badgeSettings setObject:[UIColor colorWithCSS:badgeSettings[@"TextColor"]] ? : [UIColor whiteColor] forKey:@"TextColor"];
  [badgeSettings setObject:[UIColor colorWithCSS:badgeSettings[@"ShadowColor"]] ? : [UIColor clearColor] forKey:@"ShadowColor"];

  %init(BadgeTextHook);
}
