#include <dlfcn.h>

#include <Foundation/Foundation.h>

#define cacheDir "/var/mobile/Library/Caches/NeonCache"
//#define renderDir "/var/mobile/Library/Caches/NeonCache/IconRender"
//#define staticClock "/var/mobile/Library/Caches/NeonCache/IconRender/NeonStaticClockIcon.png"

typedef struct SBIconImageInfo {
  CGSize size;
  double scale;
  double continuousCornerRadius;
} SBIconImageInfo;

// i'm not even gonna rant about this but WHOEVER DID THIS TO THE LIVE CLOCK ICON SUCKS
typedef struct SBHClockApplicationIconImageMetrics {
  CGFloat secondsHandWidth;
  CGFloat secondsHandLength;
  CGFloat secondsHandleLength;
  CGFloat secondsHandRingDiameter;
  CGFloat secondsHandRingKnockoutDiameter;
  CGSize secondsHandBounds;
  CGFloat minutesHandWidth;
  CGFloat minutesHandLength;
  CGFloat minutesHandRingDiameter;
  CGFloat minutesHandRingKnockoutDiameter;
  CGSize minutesHandBounds;
  CGFloat shadowRadius;
  CGFloat shadowInset;
  CGFloat hoursHandWidth;
  CGFloat hoursHandLength;
  CGSize hoursHandBounds;
  CGFloat separatorWidth;
  CGFloat separatorLength;
  CGFloat separatorExtraLength;
  CGFloat faceRadius;
  CGFloat contentsScale;
  SBIconImageInfo iconImageInfo;
} SBHClockApplicationIconImageMetrics;

@interface LSApplicationProxy : NSObject
@property (nonatomic, copy) NSString *boundApplicationIdentifier;
@property (nonatomic, copy) NSString * _boundApplicationIdentifier;
@property (nonatomic, readonly) NSString *localizedName;
@property (nonatomic, readonly) NSString *applicationIdentifier;
@property (nonatomic, readonly) NSURL *bundleURL;
@property (getter=isInstalled, nonatomic, readonly) BOOL installed;
// @property (nonatomic, readonly) BOOL isRestricted;
@property (readonly) NSString * applicationType;
+ (LSApplicationProxy *)applicationProxyForIdentifier:(NSString *)identifier;
@end

@interface _UIAssetManager
@property (nonatomic, readonly) NSBundle *bundle;
@property (nonatomic, readonly) NSString *carFileName;
@property (getter = _managingCoreGlyphs, nonatomic, readonly) BOOL managingCoreGlyphs;
+ (instancetype)assetManagerForBundle:(NSBundle *)bundle;
- (UIImage *)neonImageNamed:(NSString *)name originalImage:(UIImage *)orig configuration:(id)configuration;
@end

@interface LSApplicationWorkspace
+ (instancetype)defaultWorkspace;
- (NSMutableArray *)allApplications;
- (NSMutableArray *)allInstalledApplications;
@end

@interface UIApplication (Private)
- (NSArray *)_rootViewControllers;
@end

@interface UIImage (Private)
+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale;
+ (UIImage *)_iconForResourceProxy:(LSApplicationProxy *)proxy format:(int)format;
+ (UIImage *)_iconForResourceProxy:(LSApplicationProxy *)proxy variant:(int)variant variantsScale:(CGFloat)scale;
+ (UIImage *)_iconForResourceProxy:(LSApplicationProxy *)proxy variant:(int)variant options:(int)options variantsScale:(CGFloat)scale;
- (UIImage *)_flatImageWithColor:(UIColor *)color;
@end

@interface Neon : NSObject
+ (void)loadPrefs;
+ (NSArray *)themes;
+ (NSDictionary *)prefs;
+ (NSDictionary *)overrideThemes;
+ (NSMutableArray *)potentialFilenamesForName:(NSString *)name;
+ (NSString *)iconPathForBundleID:(NSString *)bundleID;
+ (NSString *)iconPathForBundleID:(NSString *)bundleID fromTheme:(NSString *)theme;
+ (NSString *)fullPathForImageNamed:(NSString *)name atPath:(NSString *)basePath;
+ (NSNumber *)deviceScale;
+ (NSArray *)iconEffectDevicePrefixes;
+ (NSString *)renderDir;
+ (CGSize)homescreenIconSize;
@end

@interface Neon (Images)
+ (UIImage *)getMaskImage;
+ (void)resetMask;
@end

@interface NeonRenderService : NSObject
+ (void)loadPrefs;
+ (void)setupImages;
+ (void)resetPrefs;
+ (UIImage *)underlay;
+ (UIImage *)overlayImage;
+ (void)renderIconWithApplicationProxy:(LSApplicationProxy *)proxy;
@end

@interface UIImage (Neon)
- (UIImage *)imageOfSize:(CGSize)size;
- (UIImage *)maskedImageWithBlackBackground:(BOOL)blackBackground homescreenIcon:(BOOL)icon;
@end

@interface NSDictionary (Neon)
+ (NSDictionary *)dictionaryWithFile:(NSString *)path;
- (void)writeToPath:(NSString *)path;
@end

@interface NSArray (Neon)
+ (NSArray *)arrayWithFile:(NSString *)path;
- (void)writeToPath:(NSString *)path;
@end
