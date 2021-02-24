#include "Neon.h"

// iOS 7 - 9 are weird; the unmasked image remains unthemed somehow
%group UnmaskedFixup
%hook SBIconImageCrossfadeView
- (void)setMasksCorners:(BOOL)masksCorners {
  %orig(NO);
}
%end
%end

@interface SBFolderIconImageView
@property (nonatomic, retain) UIView *backgroundView;
@end

%hook SBFolderIconImageView

%group FolderMask13Later

- (void)setBackgroundView:(UIView *)backgroundView {
  UIImage *mask = [%c(Neon) getMaskImage];
  CALayer *layer = [CALayer layer];
  layer.frame = backgroundView.bounds;
  layer.contents = (id)[mask CGImage];
  UIView *customView = backgroundView;
  customView.layer.mask = layer;
  customView.layer.masksToBounds = YES;
  %orig(customView);
}

- (BOOL)hasCustomBackgroundView { return NO; }

%end

%group FolderMask7To12

- (instancetype)initWithFrame:(CGRect)frame {
  self = %orig;
  UIView *backgroundView = MSHookIvar<UIView *>(self, "_backgroundView");
  UIImage *mask = [%c(Neon) getMaskImage];
  CALayer *layer = [CALayer layer];
  layer.frame = backgroundView.bounds;
  layer.contents = (id)[mask CGImage];
  backgroundView.layer.mask = layer;
  backgroundView.layer.masksToBounds = YES;
  return self;
}

- (UIImage *)_currentOverlayImage { return [[%c(Neon) getMaskImage] imageOfSize:%orig.size] ? : %orig; }

%end

%end

%group MaskOverlayFix13Later
%hook SBIconImageView
- (UIImage *)_currentOverlayImage { return [%c(Neon) getMaskImage] ? : %orig; }
%end
%end

@interface SBIconImageCrossfadeView : UIView
@end

%group AnimationFix11Later

%hook SBIconImageCrossfadeView

- (void)_updateCornerMask {
  CALayer *mask = [CALayer layer];
  mask.contents = (id)[[%c(Neon) getMaskImage] CGImage];
  mask.frame = CGRectMake(0, 0, 60, 60);
  self.layer.masksToBounds = YES;
  self.layer.mask = mask;
}

%end

%end

@interface SBBookmarkIcon
- (UIImage *)unmaskedIconImageWithInfo:(SBIconImageInfo)info;
@end
@interface SBApplicationIcon
- (NSString *)applicationBundleID;
@end
%hook SBBookmarkIcon
- (UIImage *)iconImageWithInfo:(SBIconImageInfo)info { return [[self unmaskedIconImageWithInfo:info] maskedImageWithBlackBackground:YES homescreenIcon:YES]; }
%end

%group CrappyiOS14Workaround
%hook SBApplicationIcon

- (UIImage *)iconImageWithInfo:(SBIconImageInfo)info {
  if ([[self applicationBundleID] isEqualToString:@"com.apple.mobilecal"]) return %orig;
  NSString *path = [%c(Neon) iconPathForBundleID:[self applicationBundleID]];
  return [((path) ? [UIImage imageWithContentsOfFile:path] : %orig) maskedImageWithBlackBackground:NO homescreenIcon:YES];
}

%end
%end

%ctor {
  if (kCFCoreFoundationVersionNumber < 1348.00) %init(UnmaskedFixup);
  BOOL shouldEnable = NO;
  for (NSString *theme in [%c(Neon) themes]) {
    for (NSString *format in @[@"/Library/Themes/%@/Bundles/com.apple.mobileicons.framework/", @"/Library/Themes/%@/com.apple.mobileicons.framework/"]) {
      NSString *maskPath = [NSString stringWithFormat:format, theme];
      if ([[NSFileManager defaultManager] fileExistsAtPath:maskPath]) {
        shouldEnable = YES;
        break;
      }
    }
  }
  if (kCFCoreFoundationVersionNumber >= 1740.00 && (shouldEnable || [[[%c(Neon) prefs] objectForKey:@"kGlyphMode"] boolValue])) %init(CrappyiOS14Workaround);
  if (!shouldEnable) return;
  %init;
  if (kCFCoreFoundationVersionNumber >= 1443.00) %init(AnimationFix11Later);
  if (kCFCoreFoundationVersionNumber >= 1665.15) {
    %init(MaskOverlayFix13Later);
    %init(FolderMask13Later);
  } else %init(FolderMask7To12);
}
