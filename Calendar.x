// based on https://github.com/AnemoneTeam/Anemone-OSS. coolstar, thank you.

#include "Neon.h"
#include "UIColor+CSSColors.h"

void drawStringInContextWithSettingsDict(NSString *str, CGContextRef ctx, NSDictionary *dict, CGSize imageSize, UIColor *fallbackColor, BOOL forCalendar, UIFont *defaultFont);

@interface ISImage : NSObject
- (instancetype)initWithCGImage:(CGImageRef)CGImage scale:(CGFloat)scale;
@end

@interface ISImageDescriptor
@property (assign, nonatomic) CGSize size;
@property (assign, nonatomic) BOOL shouldApplyMask;
@end

NSMutableDictionary *dateSettings;
NSMutableDictionary *daySettings;

void drawIconIntoContext(CGContextRef ctx, CGSize imageSize, BOOL masked, UIImage *base) {
  if (masked) CGContextClipToMask(ctx, CGRectMake(0, 0, imageSize.width, imageSize.height), [%c(Neon) getMaskImage].CGImage);
  if ([%c(NeonRenderService) underlay]) [[%c(NeonRenderService) underlay] drawInRect:CGRectMake(0, 0, imageSize.height, imageSize.width)];
  if (!base) base = [UIImage imageWithContentsOfFile:[%c(Neon) iconPathForBundleID:@"com.apple.mobilecal"]];
  if (base) [base drawInRect:CGRectMake(0, 0, imageSize.height, imageSize.width)];
  else {
    [[UIColor whiteColor] setFill];
    UIRectFill(CGRectMake(0, 0, imageSize.height, imageSize.width));
  }
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  NSDate *date = [NSDate date];
  if ([dateSettings[@"FontSize"] intValue] != 0) {
    dateFormatter.dateFormat = @"d";
    drawStringInContextWithSettingsDict([dateFormatter stringFromDate:date], ctx, dateSettings, imageSize, [UIColor blackColor], YES, nil);
  }
  if ([daySettings[@"FontSize"] intValue] != 0) {
    dateFormatter.dateFormat = @"EEEE";
    drawStringInContextWithSettingsDict([dateFormatter stringFromDate:date], ctx, daySettings, imageSize, [UIColor redColor], YES, nil);
  }
  if ([%c(NeonRenderService) overlayImage]) [[%c(NeonRenderService) overlayImage] drawInRect:CGRectMake(0, 0, imageSize.height, imageSize.width)];
}

UIImage *calendarIconForSize(CGSize imageSize, BOOL masked) {
  UIGraphicsBeginImageContextWithOptions(imageSize, NO, [UIScreen mainScreen].scale);
  drawIconIntoContext(UIGraphicsGetCurrentContext(), imageSize, masked, nil);
  UIImage *icon = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return icon;
}

%group Calendar
%hook CUIKIcon
- (ISImage *)imageForImageDescriptor:(ISImageDescriptor *)descriptor {
  UIImage *icon = calendarIconForSize(descriptor.size, descriptor.shouldApplyMask);
  ISImage *image = [[%c(ISImage) alloc] initWithCGImage:icon.CGImage scale:[UIScreen mainScreen].scale];
  return image;
}
%end
%end

%group Calendar_1012

%hook CUIKCalendarApplicationIcon
+ (void)_drawIconInContext:(CGContextRef)ctx imageSize:(CGSize)imageSize iconBase:(UIImage *)base calendar:(NSCalendar *)calendar dayNumberString:(NSString *)dayNumberString dateNameBlock:(id)dateNameBlock dateNameFormatType:(long long)dateNameFormatType format:(long long)format showGrid:(BOOL)showGrid {
  drawIconIntoContext(ctx, imageSize, YES, base);
}
%end

%hook WGCalendarWidgetInfo
- (UIImage *)_iconWithFormat:(int)format { return calendarIconForSize(%orig.size, YES); }
- (UIImage *)_queue_iconWithFormat:(int)format forWidgetWithIdentifier:(NSString *)widgetIdentifier extension:(id)extension { return calendarIconForSize(%orig.size, YES); }
%end

%end

%group CalendarOlder
%hook SBCalendarApplicationIcon
- (void)_drawIconIntoCurrentContextWithImageSize:(CGSize)imageSize iconBase:(UIImage *)base { drawIconIntoContext(UIGraphicsGetCurrentContext(), imageSize, YES, base); }
- (UIImage *)_compositedIconImageForFormat:(int)format withBaseImageProvider:(UIImage *(^)())imageProvider { return calendarIconForSize(imageProvider().size, YES); }
%end
%end

void loadPrefsForInfoPath(NSString *path) {
  NSDictionary *themeDict = [NSDictionary dictionaryWithFile:path];
  if (themeDict) {
    dateSettings = [themeDict[@"CalendarIconDateSettings"] mutableCopy];
    daySettings = [themeDict[@"CalendarIconDaySettings"] mutableCopy];
  }
}

void fixupColor(NSMutableDictionary *dict, NSString *key) { if (dict[key]) [dict setObject:[UIColor colorWithCSS:dict[key]] forKey:key]; }

%ctor {
  // valentine is a tweak of mine that changes the calendar icon's style to the ios 14 beta 2 one; so if it's installed, i don't wanna override that
  if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Valentine.dylib"]) return;
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon)) return;
  dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonKit.dylib", RTLD_LAZY);

  if (![%c(Neon) prefs]) return;
  NSString *overrideTheme = [[%c(Neon) overrideThemes] objectForKey:@"com.apple.mobilecal"];
  if (overrideTheme) {
    if ([overrideTheme isEqualToString:@"none"]) return;
    NSString *path = [NSString stringWithFormat:@"/Library/Themes/%@/Info.plist", overrideTheme];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) loadPrefsForInfoPath(path);
  } else {
    for (NSString *theme in [%c(Neon) themes]) {
      NSString *path = [NSString stringWithFormat:@"/Library/Themes/%@/Info.plist", theme];
      if ([[NSFileManager defaultManager] fileExistsAtPath:path]) loadPrefsForInfoPath(path);
      if (dateSettings || daySettings) break;
    }
  }

  if (!dateSettings) dateSettings = [NSMutableDictionary new];
  if (!daySettings) daySettings = [NSMutableDictionary new];

  if (!dateSettings[@"FontSize"]) [dateSettings setObject:@39.5 forKey:@"FontSize"];
  if (!daySettings[@"FontSize"]) [daySettings setObject:@10.0 forKey:@"FontSize"];

  if (dateSettings[@"TextCase"]) [dateSettings setObject:[dateSettings[@"TextCase"] lowercaseString] forKey:@"TextCase"];
  if (daySettings[@"TextCase"]) [daySettings setObject:[daySettings[@"TextCase"] lowercaseString] forKey:@"TextCase"];

  dateSettings[@"TextYoffset"] = [NSNumber numberWithFloat:[dateSettings[@"TextYoffset"] floatValue] + 12.0f];
  daySettings[@"TextYoffset"] = [NSNumber numberWithFloat:[daySettings[@"TextYoffset"] floatValue] + 6.0f];

  // as much as i refactor and optimize this thing, i still hate it. at the current state, it's ugly, but at least it's short :/
  for (NSMutableDictionary *dict in @[daySettings, dateSettings]) { fixupColor(dict, @"TextColor"); fixupColor(dict, @"ShadowColor"); }

    if (kCFCoreFoundationVersionNumber >= 1665.15) %init(Calendar);
  else if (kCFCoreFoundationVersionNumber >= 1348.00) %init(Calendar_1012);
  else %init(CalendarOlder);
}
