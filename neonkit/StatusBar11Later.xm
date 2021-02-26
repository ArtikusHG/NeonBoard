#ifdef __LP64__

#include "../Neon.h"

@interface _UIStatusBarSignalView : UIView
@property (nonatomic, assign) long long numberOfActiveBars;
@property (nonatomic, copy) UIColor *activeColor;
@property (nonatomic, retain) CALayer *customLayer;
@property (nonatomic, retain) _UIAssetManager *assetManager;
- (void)updateCustomLayerWithImageName:(NSString *)name;
@end

@interface _UIStatusBarCellularSignalView : _UIStatusBarSignalView
@end
@interface _UIStatusBarWifiSignalView : _UIStatusBarSignalView
@end

%group SignalView
%hook _UIStatusBarSignalView

%property (nonatomic, retain) CALayer *customLayer;
%property (nonatomic, retain) _UIAssetManager *assetManager;

%new
- (void)updateCustomLayerWithImageName:(NSString *)name {
  UIImage *image = [self.assetManager neonImageNamed:[NSString stringWithFormat:@"Black_%d_%@", (int)self.numberOfActiveBars, name] originalImage:nil configuration:nil];
  image = [image _flatImageWithColor:self.activeColor];
  self.customLayer.frame = CGRectMake((self.layer.bounds.size.width - image.size.width) / 2, (self.layer.bounds.size.height - image.size.height) / 2, image.size.width, image.size.height);
  self.customLayer.contents = (id)image.CGImage;
  if (!self.customLayer.superlayer) [self.layer addSublayer:self.customLayer];
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = %orig;
  self.customLayer = [CALayer layer];
  self.assetManager = [%c(_UIAssetManager) assetManagerForBundle:nil];
  return self;
}

%end
%end

%group Cellular
%hook _UIStatusBarCellularSignalView
// so this was causing a crash and i just disabled it now crash doesnt happen pogchamp
- (void)_updateCycleAnimationNow {}
- (void)_updateActiveBars { [self updateCustomLayerWithImageName:@"Bars"]; }
%end
%end
%group Wifi
%hook _UIStatusBarWifiSignalView
- (void)_updateActiveBars { [self updateCustomLayerWithImageName:@"WifiBars"]; }
- (void)_updateBars {
  %orig;
  for (CALayer *layer in self.layer.sublayers) layer.hidden = YES;
}
%end
%end

@interface _UIBatteryView : UIView
@property (nonatomic, assign) CGFloat chargePercent;
@property (nonatomic, copy) UIColor *bodyColor;
@property (nonatomic, copy) UIColor *boltColor;
@property (nonatomic, retain) CALayer *customBodyLayer;
@property (nonatomic, retain) UIImage *customBodyImage;
@property (nonatomic, retain) CALayer *customFillLayer;
@property (nonatomic, retain) UIImage *customFillImage;
@property (nonatomic, retain) CALayer *customBoltLayer;
@property (nonatomic, retain) UIImage *customBoltImage;
@property (nonatomic, retain) _UIAssetManager *assetManager;
@property (nonatomic, assign) long long chargingState;
- (UIColor *)_batteryFillColor;
@end

@interface _UIStaticBatteryView : _UIBatteryView
@end

%group Battery
%hook _UIBatteryView

%property (nonatomic, retain) CALayer *customBodyLayer;
%property (nonatomic, retain) UIImage *customBodyImage;
%property (nonatomic, retain) CALayer *customFillLayer;
%property (nonatomic, retain) UIImage *customFillImage;
%property (nonatomic, retain) CALayer *customBoltLayer;
%property (nonatomic, retain) UIImage *customBoltImage;
%property (nonatomic, retain) _UIAssetManager *assetManager;

- (CALayer *)pinLayer { return nil; }
- (CALayer *)bodyLayer { return nil; }
- (CALayer *)boltLayer { return (self.customBoltImage) ? nil : %orig; }

- (instancetype)initWithFrame:(CGRect)frame {
  self = %orig;
  self.assetManager = [%c(_UIAssetManager) assetManagerForBundle:nil];
  self.customBodyLayer = [CALayer layer];
  self.customBodyImage = [[self.assetManager neonImageNamed:@"Black_BatteryDrainingBG" originalImage:nil configuration:nil] _flatImageWithColor:self.bodyColor];
  self.customBodyLayer.contents = (id)self.customBodyImage.CGImage;
  [self.layer addSublayer:self.customBodyLayer];
  self.customFillLayer = [CALayer layer];
  self.customFillImage = [[self.assetManager neonImageNamed:@"Black_BatteryDrainingInsides" originalImage:nil configuration:nil] _flatImageWithColor:[self _batteryFillColor]];
  self.customFillLayer.contents = (id)self.customFillImage.CGImage;
  UIImage *maskImage = [[self.assetManager neonImageNamed:@"Black_BatteryDrainingInsides" originalImage:nil configuration:nil] _flatImageWithColor:[UIColor blackColor]];
  UIGraphicsBeginImageContextWithOptions(maskImage.size, NO, maskImage.scale);
  [maskImage drawInRect:CGRectMake(0, 0, maskImage.size.width, maskImage.size.height) blendMode:kCGBlendModeNormal alpha:1.0f];
  maskImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  CALayer *mask = [CALayer layer];
  mask.frame = CGRectMake(0, 0, self.customBodyImage.size.width, self.customBodyImage.size.height);
  mask.contents = (id)maskImage.CGImage;
  self.customFillLayer.mask = mask;
  [self.layer addSublayer:self.customFillLayer];
  self.customBoltLayer = [CALayer layer];
  self.customBoltImage = [[self.assetManager neonImageNamed:@"Black_BatteryChargingAccessory" originalImage:nil configuration:nil] _flatImageWithColor:self.bodyColor];
  self.customBoltLayer.contents = (id)self.customBoltImage.CGImage;
  self.customBoltLayer.hidden = self.chargingState != 0;
  return self;
}

- (void)_updateFillLayer {
  // doesnt work on init; lets just set it here.
  self.customBodyLayer.frame = CGRectMake((self.layer.bounds.size.width - self.customBodyImage.size.width) / 2, (self.layer.bounds.size.height - self.customBodyImage.size.height) / 2, self.customBodyImage.size.width, self.customBodyImage.size.height);
  self.customFillLayer.frame = CGRectMake((self.layer.bounds.size.width - self.customFillImage.size.width) / 2, (self.layer.bounds.size.height - self.customFillImage.size.height) / 2, self.customFillImage.size.width * self.chargePercent, self.customFillImage.size.height);
  self.customBoltLayer.frame = CGRectMake((self.layer.bounds.size.width - self.customBoltImage.size.width) / 2, (self.layer.bounds.size.height - self.customBoltImage.size.height) / 2, self.customBoltImage.size.width, self.customBoltImage.size.height);
}

- (void)_updateFillColor {
  self.customFillImage = [self.customFillImage _flatImageWithColor:[self _batteryFillColor]];
  self.customFillLayer.contents = (id)self.customFillImage.CGImage;
}

- (void)_updateBolt {
  if (!self.customBoltImage) %orig;
  else self.customBoltLayer.hidden = self.chargingState != 0;
}

%end
%end

// %init (Battery, _UIBatteryView = BatteryClass) just gave a bunch of errors; frick it.
// turns out i'm not the only one with the issue, and nobody cares it seems https://github.com/theos/logos/issues/43
%group Battery13
%hook _UIStaticBatteryView

- (instancetype)initWithFrame:(CGRect)frame {
  self = %orig;
  self.assetManager = [%c(_UIAssetManager) assetManagerForBundle:nil];
  self.customBodyLayer = [CALayer layer];
  self.customBodyImage = [[self.assetManager neonImageNamed:@"Black_BatteryDrainingBG" originalImage:nil configuration:nil] _flatImageWithColor:self.bodyColor];
  self.customBodyLayer.contents = (id)self.customBodyImage.CGImage;
  [self.layer addSublayer:self.customBodyLayer];
  self.customFillLayer = [CALayer layer];
  self.customFillImage = [[self.assetManager neonImageNamed:@"Black_BatteryDrainingInsides" originalImage:nil configuration:nil] _flatImageWithColor:[self _batteryFillColor]];
  self.customFillLayer.contents = (id)self.customFillImage.CGImage;
  UIImage *maskImage = [[self.assetManager neonImageNamed:@"Black_BatteryDrainingInsides" originalImage:nil configuration:nil] _flatImageWithColor:[UIColor blackColor]];
  UIGraphicsBeginImageContextWithOptions(maskImage.size, NO, maskImage.scale);
  [maskImage drawInRect:CGRectMake(0, 0, maskImage.size.width, maskImage.size.height) blendMode:kCGBlendModeNormal alpha:1.0f];
  maskImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  CALayer *mask = [CALayer layer];
  mask.frame = CGRectMake(0, 0, self.customBodyImage.size.width, self.customBodyImage.size.height);
  mask.contents = (id)maskImage.CGImage;
  self.customFillLayer.mask = mask;
  [self.layer addSublayer:self.customFillLayer];
  self.customBoltLayer = [CALayer layer];
  self.customBoltImage = [[self.assetManager neonImageNamed:@"Black_BatteryChargingAccessory" originalImage:nil configuration:nil] _flatImageWithColor:self.boltColor];
  self.customBoltLayer.contents = (id)self.customBoltImage.CGImage;
  self.customBoltLayer.hidden = self.chargingState != 0;
  return self;
}

- (void)_updateFillLayer {
  // doesnt work on init; lets just set it here.
  self.customBodyLayer.frame = CGRectMake((self.layer.bounds.size.width - self.customBodyImage.size.width) / 2, (self.layer.bounds.size.height - self.customBodyImage.size.height) / 2, self.customBodyImage.size.width, self.customBodyImage.size.height);
  self.customFillLayer.frame = CGRectMake((self.layer.bounds.size.width - self.customFillImage.size.width) / 2, (self.layer.bounds.size.height - self.customFillImage.size.height) / 2, self.customFillImage.size.width * self.chargePercent, self.customFillImage.size.height);
  self.customBoltLayer.frame = CGRectMake((self.layer.bounds.size.width - self.customBoltImage.size.width) / 2, (self.layer.bounds.size.height - self.customBoltImage.size.height) / 2, self.customBoltImage.size.width, self.customBoltImage.size.height);
}

- (void)_updateFillColor {
  self.customFillImage = [self.customFillImage _flatImageWithColor:[self _batteryFillColor]];
  self.customFillLayer.contents = (id)self.customFillImage.CGImage;
}

- (void)_updateBolt {
  if (!self.customBoltImage) %orig;
  else self.customBoltLayer.hidden = self.chargingState != 0;
}

%end
%end

%ctor {
  if (kCFCoreFoundationVersionNumber < 1443.00) return;
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon)) return;
  // dude.... maybe just.... do = NO lol
  BOOL enableCellular = NO;
  BOOL enableWifi = NO;
  BOOL enableBattery = NO;
  for (NSString *theme in [%c(Neon) themes]) {
    NSString *basePath = [NSString stringWithFormat:@"/Library/Themes/%@/UIImages/", theme];
    // wow, we can convert string to booleans
    if (!enableCellular) enableCellular = ([%c(Neon) fullPathForImageNamed:@"Black_0_Bars" atPath:basePath]);
    if (!enableWifi) enableWifi = ([%c(Neon) fullPathForImageNamed:@"Black_0_WifiBars" atPath:basePath]);
    if (!enableBattery) enableBattery = ([%c(Neon) fullPathForImageNamed:@"Black_BatteryDrainingBG" atPath:basePath]);
    if (enableCellular && enableWifi && enableBattery) break;
  }
  if (enableCellular || enableWifi) {
    %init(SignalView);
    if (enableCellular) %init(Cellular);
    if (enableWifi) %init(Wifi);
  }
  if (enableBattery) {
    %init(Battery);
    if (kCFCoreFoundationVersionNumber >= 1665.15) %init(Battery13);
  }
}

#endif
