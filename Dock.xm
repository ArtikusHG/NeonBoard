#include <Neon.h>

CGFloat dockCornerRadius;
CGFloat customDockY;
NSString *maskPath;
NSString *overlayPath;

%group BackgroundRadius
%hook UITraitCollection
- (CGFloat)displayCornerRadius { return dockCornerRadius; }
%end
%end

@interface SBDockView : UIView
@property (nonatomic, retain) CALayer *maskLayer;
@property (nonatomic, retain) CALayer *overlayLayer;
@property (nonatomic, retain) UIImage *maskImage;
@property (nonatomic, retain) UIImage *overlayImage;
@end

@interface CALayer (Backdrop)
@property (getter = isEnabled) BOOL enabled;
@end

%group CustomBackground
%hook SBDockView

%property (nonatomic, retain) CALayer *maskLayer;
%property (nonatomic, retain) CALayer *overlayLayer;
%property (nonatomic, retain) UIImage *maskImage;
%property (nonatomic, retain) UIImage *overlayImage;

- (instancetype)initWithDockListView:(id)dockListView forSnapshot:(BOOL)forSnapshot {
  self = %orig;
  // dat one small line at the top that appears when u mask/replace the background
  MSHookIvar<UIView *>(self, "_highlightView").hidden = YES;
  UIView *backgroundView = MSHookIvar<UIView *>(self, "_backgroundView");
  if (overlayPath) {
    NSArray *overlayNames = @[@"ModernDockOverlay", @"SBDockBG", @"SBDock"];
    for (NSString *name in overlayNames) {
      if ((self.overlayImage = [UIImage imageNamed:name inBundle:[NSBundle bundleWithPath:overlayPath]])) {
        // this one line of code took two days 2-4 hours each to figure out. aight imma head out lmfaoooooo
        self.overlayImage = [UIImage imageWithCGImage:self.overlayImage.CGImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        self.overlayLayer = [CALayer layer];
        self.overlayLayer.contents = (id)self.overlayImage.CGImage;
        break;
      }
    }
    [backgroundView.layer addSublayer:self.overlayLayer];
  }
  if (maskPath) {
    NSArray *maskNames = @[@"ModernDockMask", @"SBDockMask"];
    for (NSString *name in maskNames) {
      if ((self.maskImage = [UIImage imageNamed:name inBundle:[NSBundle bundleWithPath:maskPath]])) {
        self.maskImage = [UIImage imageWithCGImage:self.maskImage.CGImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        self.maskLayer = [CALayer layer];
        self.maskLayer.contents = (id)self.maskImage.CGImage;
        break;
      }
    }
  } else if (self.overlayImage) {
    self.maskLayer = [CALayer layer];
    self.maskLayer.contents = (id)[[self.overlayImage copy] CGImage]; // same image to multiple layer doesn't work, so copy
  }
  backgroundView.layer.mask = self.maskLayer;
  if ([backgroundView.layer respondsToSelector:@selector(setEnabled:)]) backgroundView.layer.enabled = NO;
  return self;
}

// i honestly don't even give a shit anymore. roast me on discord for hooking layoutSubviews. i dare you, do it.
- (void)layoutSubviews {
  %orig;
  UIView *backgroundView = MSHookIvar<UIView *>(self, "_backgroundView");
  // so i'm probably gonna forget what i even meant to do here if i have to come back to this in a while, SO
  // if the width is bigger than the width of the dock view (so basically, the width of the screen), that means it doesn't fit. so, we make it fit (second line of code inside if statement)
  // but before that, we need to find out by how much we changed the width so that we don't end up with a dock background that looks like a shitty abstract russian meme. this is what the first line does: divide the bad width by the good one. and adjust the height to that.
  // hopefully though i'll NEVER have to come back to this module (or at least this part of the module) lmfaoooo
  CGFloat width = self.overlayImage.size.width;
  CGFloat height = self.overlayImage.size.height;
  if (width > self.bounds.size.width) {
    height = height * (self.bounds.size.width / width);
    width = self.bounds.size.width;
  }
  CGRect frame = CGRectMake((backgroundView.bounds.size.width - self.bounds.size.width) / 2 + backgroundView.bounds.origin.x, self.bounds.size.height - self.overlayImage.size.height + customDockY, width, height);
  // this one also worked (*ahem* on my device) but i KINDA DIDNT LIKE THE part where its " / 4 + 2" that i did for ABSOLUTELY NO REASON, based exclusively on "this shit looks kinda off, lets divide it more and see if that helps"
  //CGRect frame = CGRectMake((backgroundView.bounds.size.width - self.bounds.size.width) / 4 + 2, self.bounds.size.height - self.overlayImage.size.height + customDockY, width, height);
  self.maskLayer.frame = frame;
  self.overlayLayer.frame = frame;
}

- (void)setBackgroundView:(UIView *)backgroundView {
  %orig;
  if (self.overlayLayer) {
    [backgroundView.layer addSublayer:self.overlayLayer];
    backgroundView.layer.enabled = NO;
  } else if (self.maskLayer) backgroundView.layer.mask = self.maskLayer;
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
  customDockY = [[[%c(Neon) prefs] objectForKey:@"kDockY"] floatValue];
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
  if (maskPath || overlayPath) %init(CustomBackground);
}
