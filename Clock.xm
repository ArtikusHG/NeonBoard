#include "Neon.h"
#include <AppSupport/CPDistributedMessagingCenter.h>

@interface SBHClockHandsImageSet
@property (nonatomic, readwrite, strong) UIImage *seconds;
@property (nonatomic, readwrite, strong) UIImage *minutes;
@property (nonatomic, readwrite, strong) UIImage *hours;
@property (nonatomic, readwrite, strong) UIImage *hourMinuteDot;
@property (nonatomic, readwrite, strong) UIImage *secondDot;
+ (SBHClockHandsImageSet *)makeImageSetForMetrics:(SBHClockApplicationIconImageMetrics *)metrics;
@end

@interface SBClockApplicationIconImageView : UIView
@property (assign, nonatomic) BOOL showsSquareCorners;
- (void)_setAnimating:(BOOL)animating;
+ (instancetype)sharedInstance;
+ (CALayer *)makeSecondsHandLayerWithImageSet:(SBHClockHandsImageSet *)imageSet;
- (void)applyMetrics:(SBHClockApplicationIconImageMetrics)metrics;
@end

NSArray *themes;
NSString *overrideTheme;

UIImage *clockImageNamed(NSString *name) {
  if (overrideTheme) {
    NSString *path;
    if ([overrideTheme rangeOfString:@"/"].location != NSNotFound && [name isEqualToString:@"ClockIconBackgroundSquare"]) {
      NSArray *things = [overrideTheme componentsSeparatedByString:@"/"];
      path = [%c(Neon) iconPathForBundleID:things[1] fromTheme:things[0]];
    }
    else path = [%c(Neon) fullPathForImageNamed:name atPath:[NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.springboard/", overrideTheme]];
    if (path) return [UIImage imageWithContentsOfFile:path];
  } else {
    for (NSString *theme in themes) {
      NSString *path = [%c(Neon) fullPathForImageNamed:name atPath:[NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.springboard/", theme]];
      if (path) return [UIImage imageWithContentsOfFile:path];
    }
  }
  return nil;
}

UIImage *customClockBackground(CGSize size, BOOL masked) {
  UIImage *custom = clockImageNamed(@"ClockIconBackgroundSquare");
  if (!custom) return nil;
  UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
  if (masked) CGContextClipToMask(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, size.width, size.height), [%c(Neon) getMaskImage].CGImage);
  if ([%c(NeonRenderService) underlay]) [[%c(NeonRenderService) underlay] drawInRect:CGRectMake(0, 0, size.height, size.width)];
  [custom drawInRect:CGRectMake(0, 0, size.width, size.height)];
  if ([%c(NeonRenderService) overlayImage]) [[%c(NeonRenderService) overlayImage] drawInRect:CGRectMake(0, 0, size.height, size.width)];
  custom = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return custom;
}

UIImage *proportionalResize(UIImage *image, CGSize size) {
  if (image.size.height <= size.height) return image;
  return [image imageOfSize:CGSizeMake(image.size.width * size.height / image.size.height, size.height)];
}

%group AllVersions
%hook SBClockApplicationIconImageView
- (UIImage *)contentsImage { return customClockBackground(%orig.size, YES) ? : %orig; }
- (UIImage *)squareContentsImage { return customClockBackground(%orig.size, NO) ? : %orig; }
%end
%end

%group iOS7To13

%hook SBClockApplicationIconImageView
- (instancetype)initWithFrame:(CGRect)frame {
  self = %orig;
  NSMutableDictionary *files = [NSMutableDictionary dictionaryWithDictionary:@{
    @"ClockIconSecondHand" : @"seconds",
    @"ClockIconMinuteHand" : @"minutes",
    @"ClockIconHourHand" : @"hours",
    @"ClockIconBlackDot" : @"blackDot",
    @"ClockIconRedDot" : @"redDot",
    @"ClockIconHourMinuteDot" : @"blackDot",
    @"ClockIconSecondDot" : @"redDot"
  }];
  if (kCFCoreFoundationVersionNumber >= 1665.15) {
    [files setObject:@"hourMinuteDot" forKey:@"ClockIconBlackDot"];
    [files setObject:@"secondDot" forKey:@"ClockIconRedDot"];
    [files setObject:@"hourMinuteDot" forKey:@"ClockIconHourMinuteDot"];
    [files setObject:@"secondDot" forKey:@"ClockIconSecondDot"];
  }
  for (NSString *key in [files allKeys]) {
    UIImage *image = clockImageNamed(key);
    if (!image) continue;
    const char *ivarName = [[@"_" stringByAppendingString:[files objectForKey:key]] cStringUsingEncoding:NSUTF8StringEncoding];
    MSHookIvar<CALayer *>(self, ivarName).backgroundColor = [UIColor clearColor].CGColor;
    MSHookIvar<CALayer *>(self, ivarName).contents = (id)[image CGImage];
  }
  return self;
}
%end

%end

%group iOS14Later

%hook SBClockApplicationIconImageView

SBHClockApplicationIconImageMetrics origMetrics;

// override this so that the original instance is forced to be recreated when we initialize our own icon for the render (so that the custom arrows get updated and applied)
+ (SBHClockHandsImageSet *)imageSetForMetrics:(SBHClockApplicationIconImageMetrics *)metrics { return [self makeImageSetForMetrics:metrics]; }

+ (SBHClockHandsImageSet *)makeImageSetForMetrics:(SBHClockApplicationIconImageMetrics *)metrics {
  SBHClockHandsImageSet *customSet = %orig;
  origMetrics = MSHookIvar<SBHClockApplicationIconImageMetrics>(customSet, "_metrics");
  if (UIImage *seconds = clockImageNamed(@"ClockIconSecondHand")) customSet.seconds = proportionalResize(seconds, customSet.seconds.size);
  if (UIImage *minutes = clockImageNamed(@"ClockIconMinuteHand")) customSet.minutes = proportionalResize(minutes, customSet.minutes.size);
  if (UIImage *hours = clockImageNamed(@"ClockIconHourHand")) customSet.hours = proportionalResize(hours, customSet.hours.size);
  if (UIImage *hourMinuteDot = clockImageNamed(@"ClockIconBlackDot")) customSet.hourMinuteDot = proportionalResize(hourMinuteDot, customSet.hourMinuteDot.size);
  if (UIImage *secondDot = clockImageNamed(@"ClockIconRedDot")) customSet.secondDot = proportionalResize(secondDot, customSet.secondDot.size);
  return customSet;
}

%end

%end

%group Render

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
  %orig;
  CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"com.artikus.neonboard"];
  [center runServerOnCurrentThread];
  [center registerForMessageName:@"renderClockIcon" target:self selector:@selector(renderClockIcon)];
}

%new
- (void)renderClockIcon {
  // update prefs first
  [%c(Neon) loadPrefs];
  if ([[[%c(Neon) prefs] objectForKey:@"kNoStaticClock"] boolValue]) return;
  overrideTheme = [[%c(Neon) overrideThemes] objectForKey:@"com.apple.mobiletimer"];
  if ((overrideTheme && [overrideTheme isEqualToString:@"none"]) || ![%c(Neon) iconPathForBundleID:@"com.apple.mobiletimer"]) return;
  if ([%c(Neon) themes] && [%c(Neon) themes].count > 0) themes = [%c(Neon) themes];
  // stuff
  CGSize size = [%c(Neon) homescreenIconSize];
  CGRect rect = CGRectMake(0, 0, size.width, size.height);
  SBClockApplicationIconImageView *view = [[%c(SBClockApplicationIconImageView) alloc] initWithFrame:rect];
  view.showsSquareCorners = YES;
  if (kCFCoreFoundationVersionNumber >= 1740) [view applyMetrics:origMetrics];
  [view _setAnimating:NO];
  // these can be probably calculated via degrees but i'm lazy; i wish setOverrideDate existed on ios <13 :/
  [MSHookIvar<CALayer *>(view, "_hours") setAffineTransform:CGAffineTransformMake(0.577, -0.816, 0.816, 0.577, 0, 0)];
  [MSHookIvar<CALayer *>(view, "_minutes") setAffineTransform:CGAffineTransformMake(0.453, 0.891, -0.891, 0.453, 0, 0)];
  [MSHookIvar<CALayer *>(view, "_seconds") setAffineTransform:CGAffineTransformMakeRotation(M_PI)];
  // render stuff
  UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
  if ([[[%c(Neon) prefs] objectForKey:@"kMaskRendered"] boolValue])
    CGContextClipToMask(UIGraphicsGetCurrentContext(), rect, [%c(Neon) getMaskImage].CGImage);
  if (kCFCoreFoundationVersionNumber < 1740) {
    UIImage *background = [UIImage _applicationIconImageForBundleIdentifier:@"com.apple.mobiletimer" format:2 scale:[UIScreen mainScreen].scale];
    [background drawInRect:rect];
  }
  [view.layer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
  [UIImagePNGRepresentation(finalImage) writeToFile:[[%c(Neon) renderDir] stringByAppendingPathComponent:@"NeonStaticClockIcon.png"] atomically:YES];
  UIGraphicsEndImageContext();
}

%end

%end

%ctor {
  if (kCFCoreFoundationVersionNumber < 847.20) return; // iOS 7 introduced live clock so
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon)) return;
  %init(Render);
  overrideTheme = [[%c(Neon) overrideThemes] objectForKey:@"com.apple.mobiletimer"];
  if (overrideTheme && [overrideTheme isEqualToString:@"none"]) return;
  if ([%c(Neon) themes] && [%c(Neon) themes].count > 0) {
    themes = [%c(Neon) themes];
    %init(AllVersions);
    if (kCFCoreFoundationVersionNumber >= 1740) %init(iOS14Later);
    else %init(iOS7To13);
  }
}
