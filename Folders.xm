#include <objc/runtime.h>
#include "Neon.h"

@interface SBFolderIconBackgroundView : UIView
@property (nonatomic, retain) CALayer *customLayer;
@end

@interface SBFolderBackgroundView : UIView
@property (nonatomic, retain) CALayer *customLayer;
@end

@interface SBFolderIconView
- (SBFolderIconBackgroundView *)iconBackgroundView;
@end

@interface SBFolder
@property (nonatomic, copy) NSString *displayName;
@end

@interface SBFolderIcon
- (SBFolder *)folder;
@end

@interface SBFolderIconImageView
@property (nonatomic, retain) UIView *backgroundView;
@property (nonatomic, retain) UIImageView *neonCustomBackgroundView;
@end

NSString *iconBasePath;
NSString *backgroundBasePath;

%group FolderIcon13Later

// workaround for Folded trying to hide blurView which doesn't exist on UIImageView, causing a crash
%hook UIImageView
%new
- (UIView *)blurView { return nil; }
%end

%hook SBFolderIconImageView

%property (nonatomic, retain) UIImageView *neonCustomBackgroundView;

- (void)setBackgroundView:(UIView *)view {
  if (self.neonCustomBackgroundView) %orig(self.neonCustomBackgroundView);
  UIImage *customImage = [UIImage imageNamed:@"ANEMFolderIconBG" inBundle:[NSBundle bundleWithPath:iconBasePath]];
  if (customImage && !self.neonCustomBackgroundView) {
    self.neonCustomBackgroundView = [[UIImageView alloc] initWithImage:customImage];
    self.neonCustomBackgroundView.frame = view.frame;
    %orig(self.neonCustomBackgroundView);
  } else %orig;
}

- (void)layoutSubviews {
  %orig;
  [self setBackgroundView:self.neonCustomBackgroundView];
}

//- (BOOL)hasCustomBackgroundView { return NO; }

/*- (void)setIcon:(SBFolderIcon *)icon location:(id)location animated:(BOOL)animated {
  %orig;
  NSLog(@"NEONDEBUG: %@", icon);
  self.neonCustomBackgroundView.image = nil;
  //NSLog(@"NEONDEBUG: %@", [icon folder].displayName);
  if (iconBasePath) {
    if (!self.neonCustomBackgroundView) self.neonCustomBackgroundView = [UIImageView new];
    if (UIImage *customImage = [UIImage imageNamed:[NSString stringWithFormat:@"ANEMFolderIconBG-%@", [icon folder].displayName] inBundle:[NSBundle bundleWithPath:iconBasePath]]) {
      self.neonCustomBackgroundView.image = customImage;
      self.backgroundView = self.neonCustomBackgroundView;
    }
  }
}*/

%end

%end

%group FolderIcon7To12

%hook SBFolderIconBackgroundView

%property (nonatomic, retain) CALayer *customLayer;

- (instancetype)initWithDefaultSize {
  self = %orig;
  self.customLayer = [CALayer layer];
  self.customLayer.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
  [self.layer insertSublayer:self.customLayer atIndex:0];
  if (UIImage *customBackground = [UIImage imageNamed:@"ANEMFolderIconBG" inBundle:[NSBundle bundleWithPath:iconBasePath]]) {
    self.customLayer.contents = (id)customBackground.CGImage;
    self.layer.backgroundColor = [UIColor clearColor].CGColor;
  }
  return self;
}

// this turns the weird idk what into what is simply a background color, which we can set to a transparent one to hide the original folder background (ios 7 - 12)
- (BOOL)wantsBlur:(id)arg { return NO; }

%end

%hook SBFolderIconView

- (void)setIcon:(SBFolderIcon *)icon {
  %orig;
  if (iconBasePath) {
    UIImage *customBackground = [UIImage imageNamed:[NSString stringWithFormat:@"ANEMFolderIconBG-%@", [icon folder].displayName] inBundle:[NSBundle bundleWithPath:iconBasePath]];
    if (customBackground) [self iconBackgroundView].customLayer.contents = (id)customBackground.CGImage;
  }
}

%end

%end

%group FolderBackground

%hook SBFolderBackgroundView

%property (nonatomic, retain) CALayer *customLayer;

- (instancetype)initWithFrame:(CGRect)frame {
  self = %orig;
  for (UIView *view in self.subviews) [view removeFromSuperview];
    if (UIImage *customBackground = [UIImage imageNamed:@"ANEMFolderBackground" inBundle:[NSBundle bundleWithPath:backgroundBasePath]]) {
      self.customLayer = [CALayer layer];
      self.customLayer.contents = (id)customBackground.CGImage;
      [self.layer insertSublayer:self.customLayer atIndex:0];
    }
    return self;
  }

  - (void)layoutSubviews {
    %orig;
    self.customLayer.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
  }

  %end

  %end

  %ctor {
    if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
    if (!%c(Neon)) return;
    for (NSString *theme in [%c(Neon) themes]) {
      NSString *path = [NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.springboard/", theme];
      if (!iconBasePath) {
        if ([%c(Neon) fullPathForImageNamed:@"ANEMFolderIconBG" atPath:path]) iconBasePath = path;
        else for (NSString *name in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil]) if ([name rangeOfString:@"ANEMFolderIconBG"].location != NSNotFound) iconBasePath = path;
      }
      if (!backgroundBasePath && [%c(Neon) fullPathForImageNamed:@"ANEMFolderBackground" atPath:path]) backgroundBasePath = path;
      if (iconBasePath && backgroundBasePath) break;
    }
  // we init this anyway bc there's the "ANEMFolderIconBG-FolderName" which is really crappy to detect
    if (iconBasePath) {
      if (kCFCoreFoundationVersionNumber >= 1665.15) %init(FolderIcon13Later);
      else %init(FolderIcon7To12);
    }
    if (backgroundBasePath) %init(FolderBackground);
  }
