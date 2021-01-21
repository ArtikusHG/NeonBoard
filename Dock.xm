#include <Neon.h>

@interface SBDockView : UIView
@property (nonatomic, retain) CALayer *maskLayer;
@property (nonatomic, retain) CALayer *overlayLayer;
@property (nonatomic, retain) UIImage *maskImage;
@property (nonatomic, retain) UIImage *overlayImage;
@end

@interface SBFloatingDockPlatterView : SBDockView
@end

CGFloat dockCornerRadius;
CGFloat customDockY;
CGFloat dockScale;
NSString *maskPath;
NSString *overlayPath;

%group BackgroundRadius
%hook UITraitCollection
- (CGFloat)displayCornerRadius { return dockCornerRadius; }
%end
%end

void addCustomBackgroundToInstance(SBDockView *self) {
  if (overlayPath) {
    NSArray *overlayNames = @[@"ModernDockOverlay", @"SBDockBG", @"SBDock"];
    for (NSString *name in overlayNames) {
      if ((self.overlayImage = [UIImage imageNamed:name inBundle:[NSBundle bundleWithPath:overlayPath]])) {
        // this one line of code took two days 2-4 hours each to figure out. aight imma head out lmfaoooooo
        self.overlayImage = [UIImage imageWithCGImage:self.overlayImage.CGImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        self.overlayLayer = [CALayer layer];
        self.overlayLayer.contents = (id)self.overlayImage.CGImage;
        MSHookIvar<UIView *>(self, "_backgroundView").hidden = YES;
        [self.layer insertSublayer:self.overlayLayer atIndex:0];
        break;
      }
    }
  }
  if (maskPath && !overlayPath) {
    NSArray *maskNames = @[@"ModernDockMask", @"SBDockMask"];
    for (NSString *name in maskNames) {
      if ((self.maskImage = [UIImage imageNamed:name inBundle:[NSBundle bundleWithPath:maskPath]])) {
        self.maskImage = [UIImage imageWithCGImage:self.maskImage.CGImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        self.maskLayer = [CALayer layer];
        self.maskLayer.contents = (id)self.maskImage.CGImage;
        MSHookIvar<UIView *>(self, "_backgroundView").layer.mask = self.maskLayer;
        break;
      }
    }
  }
}

void fixupFramesForInstance(SBDockView *self) {
  UIImage *image;
  if (self.overlayImage) image = self.overlayImage;
  else if (self.maskImage) image = self.maskImage;
  else return;
  CGFloat width = image.size.width;
  CGFloat height = image.size.height;
  if (width > self.bounds.size.width) {
    height = height * (self.bounds.size.width / width);
    width = self.bounds.size.width;
  }
  width *= dockScale;
  height *= dockScale;
  CGRect frame = CGRectMake((self.bounds.size.width - width) / 2, (self.bounds.size.height - height) / 2 + customDockY, width, height);
  if (self.maskLayer) self.maskLayer.frame = frame;
  if (self.overlayLayer) self.overlayLayer.frame = frame;
}

%group CustomBackground

%hook SBFloatingDockPlatterView
%property (nonatomic, retain) CALayer *maskLayer;
%property (nonatomic, retain) CALayer *overlayLayer;
%property (nonatomic, retain) UIImage *maskImage;
%property (nonatomic, retain) UIImage *overlayImage;
//- (void)setBackgroundView:(UIView *)view {}
- (instancetype)initWithFrame:(CGRect)frame {
  self = %orig;
  addCustomBackgroundToInstance(self);
  return self;
}
- (instancetype)initWithReferenceHeight:(CGFloat)height maximumContinuousCornerRadius:(CGFloat)radius {
  self = %orig;
  addCustomBackgroundToInstance(self);
  return self;
}
- (void)layoutSubviews {
  %orig;
  fixupFramesForInstance(self);
}
%end

%hook SBDockView
%property (nonatomic, retain) CALayer *maskLayer;
%property (nonatomic, retain) CALayer *overlayLayer;
%property (nonatomic, retain) UIImage *maskImage;
%property (nonatomic, retain) UIImage *overlayImage;
//- (void)setBackgroundView:(UIView *)view {}
- (instancetype)initWithDockListView:(id)dockListView forSnapshot:(BOOL)forSnapshot {
  self = %orig;
  MSHookIvar<UIView *>(self, "_highlightView").hidden = YES;
  addCustomBackgroundToInstance(self);
  return self;
}
- (void)layoutSubviews {
  %orig;
  fixupFramesForInstance(self);
}
%end

%end

%ctor {
  // idk wtf is wrong with this shit, i made it a global and it didnt work, like that it does
  NSArray *maskNames = @[@"ModernDockMask", @"SBDockMask"];
  NSArray *overlayNames = @[@"ModernDockOverlay", @"SBDockBG", @"SBDock"];
  // landscape????
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon)) return;
  for (NSString *theme in [%c(Neon) themes]) {
    NSDictionary *infoPlist = [NSDictionary dictionaryWithFile:[NSString stringWithFormat:@"/Library/Themes/%@/Info.plist", theme]];
    if (infoPlist && infoPlist[@"FloatyDockBackgroundRadius"]) {
      dockCornerRadius = [infoPlist[@"FloatyDockBackgroundRadius"] floatValue];
      %init(BackgroundRadius);
      break;
    }
  }
  for (NSString *theme in [%c(Neon) themes]) {
    NSString *basePath = [NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.springboard/", theme];
    if (!maskPath) for (NSString *name in maskNames) if ([%c(Neon) fullPathForImageNamed:name atPath:basePath]) {
      maskPath = basePath;
      break;
    }
    if (!overlayPath) for (NSString *name in overlayNames) if ([%c(Neon) fullPathForImageNamed:name atPath:basePath]) {
      overlayPath = basePath;
      break;
    }
  }
  if (maskPath || overlayPath) {
    customDockY = [[[%c(Neon) prefs] objectForKey:@"kDockY"] floatValue];
    dockScale = [[[%c(Neon) prefs] objectForKey:@"kDockScale"] floatValue];
    if (dockScale < 1.0f) dockScale = 1.0f;
    %init(CustomBackground);
  }
}
