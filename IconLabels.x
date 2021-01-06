#include "UIColor+CSSColors.h"
#include "Neon.h"

NSMutableDictionary *labelSettings;
NSCache *labelCache;

@interface SBIconLabelImageParameters
@property (nonatomic, copy, readonly) NSString *text;
@property (nonatomic, readonly) UIColor *textColor;
@property (nonatomic, readonly) UIFont *font;
@property (nonatomic, readonly) CGSize maxSize;
@property (nonatomic, readonly) CGFloat scale;
@end

@interface SBIconLabelImage : UIImage
- (instancetype)_initWithCGImage:(CGImageRef)image scale:(CGFloat)scale orientation:(UIImageOrientation)orientation parameters:(SBIconLabelImageParameters *)parameters alignmentRectInsets:(UIEdgeInsets)alignmentRectInsets baselineOffsetFromBottom:(CGFloat)baselineOffsetFromBottom;
- (instancetype)_initWithCGImage:(CGImageRef)image scale:(CGFloat)scale orientation:(UIImageOrientation)orientation parameters:(SBIconLabelImageParameters *)parameters maxSizeOffset:(CGPoint)maxSizeOffset;
@end

void drawStringInContextWithSettingsDict(NSString *str, CGContextRef ctx, NSDictionary *dict, CGSize imageSize, UIColor *fallbackColor, BOOL forCalendar, UIFont *defaultFont);

SBIconLabelImage *customImageWithParameters(SBIconLabelImageParameters *parameters) {
  SBIconLabelImage *cachedImage = [labelCache objectForKey:parameters.text];
  if (cachedImage) return cachedImage;
  UIGraphicsBeginImageContextWithOptions(parameters.maxSize, NO, parameters.scale);
  drawStringInContextWithSettingsDict(parameters.text, UIGraphicsGetCurrentContext(), labelSettings, parameters.maxSize, parameters.textColor, NO, parameters.font);
  UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  SBIconLabelImage *labelImage;
  if (@available(iOS 13, *)) labelImage = [[%c(SBIconLabelImage) alloc] _initWithCGImage:finalImage.CGImage scale:parameters.scale orientation:UIImageOrientationUp parameters:parameters alignmentRectInsets:UIEdgeInsetsZero baselineOffsetFromBottom:7.0f];
  else labelImage = [[%c(SBIconLabelImage) alloc] _initWithCGImage:finalImage.CGImage scale:parameters.scale orientation:UIImageOrientationUp parameters:parameters maxSizeOffset:CGPointMake(0, 0)];
  [labelCache setObject:labelImage forKey:parameters.text];
  return labelImage;
}

%hook SBIconLabelImage
+ (SBIconLabelImage *)imageWithParameters:(SBIconLabelImageParameters *)parameters pool:(id)pool legibilityPool:(id)legibilityPool { return customImageWithParameters(parameters); }
+ (SBIconLabelImage *)checkoutLabelImageForParameters:(SBIconLabelImageParameters *)parameters {
  if (!parameters) return %orig;
  return customImageWithParameters(parameters);
}
%end

%ctor {
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon) || ![%c(Neon) prefs]) return;

  for (NSString *theme in [%c(Neon) themes]) {
    NSDictionary *themeDict = [NSDictionary dictionaryWithFile:[NSString stringWithFormat:@"/Library/Themes/%@/Info.plist", theme]];
    labelSettings = [themeDict[@"IconLabelSettings"] mutableCopy];
    if (labelSettings && labelSettings.count != 0) break;
  }
  if (!labelSettings || labelSettings.count == 0) return;

  if (!labelSettings[@"FontSize"]) [labelSettings setObject:@12.0f forKey:@"FontSize"];
  [labelSettings setObject:[UIColor colorWithCSS:labelSettings[@"TextColor"]] ? : [UIColor whiteColor] forKey:@"TextColor"];
  [labelSettings setObject:[UIColor colorWithCSS:labelSettings[@"ShadowColor"]] ? : [UIColor clearColor] forKey:@"ShadowColor"];

  labelCache = [NSCache new];
  %init;
}
