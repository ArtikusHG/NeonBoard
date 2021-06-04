#include "Neon.h"

// Disable dark overlay
%group NoOverlay
%hook SBIconView
- (void)setHighlighted:(BOOL)isHighlighted { %orig(NO); }
%end
%end

// Hide icon labels
@interface SBIconView
@property (nonatomic, assign, getter = isLabelHidden) BOOL labelHidden;
@property (nonatomic, copy) NSString *location;
- (BOOL)shouldHideLabel;
@end
%group HideLabels
%hook SBIconView
- (void)setLabelHidden:(BOOL)labelHidden { %orig(YES); }
- (BOOL)isLabelHidden { return YES; }
- (instancetype)initWithContentType:(unsigned long long)type {
  self = %orig;
  self.labelHidden = YES;
  return self;
}
%end
%end

// Hide dock background
%group NoDockBg

%hook SBDockView
- (instancetype)initWithDockListView:(id)dockListView forSnapshot:(BOOL)forSnapshot {
  self = %orig;
  MSHookIvar<UIView *>(self, "_backgroundView").hidden = YES;
  return self;
}
- (void)setBackgroundView:(UIView *)backgroundView {}
- (void)setBackgroundAlpha:(double)setBackgroundAlpha { %orig(0); }
%end

%hook SBFloatingDockPlatterView
- (UIView *)backgroundView { return nil; }
%end

%end

// Hide page dots
%group NoPageDots
%hook SBIconListPageControl
- (void)setHidden:(BOOL)isHidden { %orig(YES); }
%end
%end

// Hide folder icon background
@interface SBFolderIconBackgroundView : UIView
@end

%group NoFolderIconBg
%hook SBFolderIconBackgroundView
- (instancetype)initWithDefaultSize {
  self = %orig;
  self.hidden = YES;
  return self;
}
%end
%end

%group NoFolderIconBgiOS13
%hook SBFolderIconImageView
- (void)setBackgroundView:(UIView *)backgroundView {}
%end
%end

%group MaskWidgets
%hook WGWidgetInfo
- (UIImage *)_queue_iconWithFormat:(int)format forWidgetWithIdentifier:(NSString *)widgetIdentifier extension:(id)extension { return [%orig maskedImageWithBlackBackground:NO homescreenIcon:NO]; }
- (UIImage *)_queue_iconWithSize:(CGSize)size scale:(CGFloat)scale forWidgetWithIdentifier:(NSString *)widgetIdentifier extension:(id)extension { return [%orig maskedImageWithBlackBackground:NO homescreenIcon:NO]; }
- (UIImage *)_iconWithFormat:(int)format { return [%orig maskedImageWithBlackBackground:NO homescreenIcon:NO]; }
%end
%end

%group ActivatorNoBlur
%hook SBActivatorIconImageView
- (void)setBackgroundView:(UIView *)view {}
%end
%end

%ctor {
  if (![[NSProcessInfo processInfo].processName isEqualToString:@"SpringBoard"]) return;
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon)) return;
  NSDictionary *prefs = [%c(Neon) prefs];
  if (!prefs) return;
  if ([[prefs valueForKey:@"kNoOverlay"] boolValue]) %init(NoOverlay);
  if ([[prefs valueForKey:@"kHideLabels"] boolValue]) %init(HideLabels);
  if ([[prefs valueForKey:@"kNoDockBg"] boolValue]) %init(NoDockBg);
  if ([[prefs valueForKey:@"kNoPageDots"] boolValue]) %init(NoPageDots);
  if ([[prefs valueForKey:@"kNoFolderIconBg"] boolValue]) {
    if (kCFCoreFoundationVersionNumber < 1665.15) %init(NoFolderIconBg);
    else %init(NoFolderIconBgiOS13);
  }
  if ([[prefs valueForKey:@"kMaskWidgets"] boolValue]) %init(MaskWidgets);
  if ([[prefs valueForKey:@"kActivatorFix"] boolValue]) %init(ActivatorNoBlur);
}
