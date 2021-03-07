#include "../Neon.h"
#include "NeonCacheManager.h"

@interface UIImageSymbolConfiguration (Private)
@property (assign, setter=_setScale:, nonatomic) long long scale;
@end

@interface UIImageAsset (Private)
@property (nonatomic, copy) NSString *assetName;
@end

@interface UIImage (asjdhbf)
@property (nonatomic, retain) UIImage *neonOrigImage;
@end

//%hook UIImage
//%property (nonatomic, retain) UIImage *neonOrigImage;
//%end

NSArray *themes;
BOOL glyphMode;

NSArray *glyphNames;

static char *UIKitCarBundle;

NSString *customPathForName(NSString *name, NSBundle *bundle) {
  for (NSString *theme in themes) {
    NSMutableArray *potentialPaths = [NSMutableArray new];
    [potentialPaths addObject:[NSString stringWithFormat:@"/Library/Themes/%@/Bundles/%@/", theme, bundle.bundleIdentifier]];
    // use com.apple.springboard instead of com.apple.SpringBoardHome and such weird shits
    if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"])
      [potentialPaths addObject:[NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.springboard/", theme]];
    // "UIImages" folder
    [potentialPaths addObject:[NSString stringWithFormat:@"/Library/Themes/%@/UIImages/", theme]];
    // "Folders" folder
    [potentialPaths addObject:[NSString stringWithFormat:@"/Library/Themes/%@/Folders/%@/", theme, bundle.bundlePath.lastPathComponent]];
    [potentialPaths addObject:[NSString stringWithFormat:@"/Library/Themes/%@/Folders/%@/", theme, bundle.bundlePath.lastPathComponent.stringByDeletingPathExtension]];
    for (NSString *imagePath in potentialPaths) {
      if (NSString *path = [%c(Neon) fullPathForImageNamed:name atPath:imagePath]) return path;
      if ([name isEqualToString:@"NewsstandIconEnglish"] || [name isEqualToString:@"NewsstandIconInternational"])
        if (NSString *path = [%c(Neon) iconPathForBundleID:@"com.apple.news" fromTheme:theme]) return path;
    }
  }
  return nil;
}

UIImage *rescaleImageIfNeeded(UIImage *custom, UIImage *orig, NSString *name) {
  if (!orig) return custom;
  // я люблю костыли)))) (don't mind the russian; this is for the music controls on 13+) (and the phone call button)
  NSArray *resize = @[@"chevron.forward", @"backward.fill", @"forward.fill", @"pause.fill", @"play.fill", @"phone", @"phone.fill", @"phone.circle.fill", @"phone.down.fill", @"phone.down", @"phone.fill.arrow.down.left", @"phone.fill.arrow.up.right", @"UISwitchKnob"];
  if (orig && [resize containsObject:name]) custom = [custom imageOfSize:orig.size];
  return custom;
}

UIImage *customUIImageWithName(NSString *name, NSBundle *bundle, UIImage *orig) {
  NSString *path = customPathForName(name, bundle);
  if (!path) return nil;
  return rescaleImageIfNeeded([UIImage imageWithContentsOfFile:path], orig, name);
}

UIImage *configureUIImage(UIImage *custom, UIImage *orig, id configuration, BOOL isTemplate) {
  if (@available(iOS 13, *)) {
    UIImage *image = custom;
    if (isTemplate) image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    //if (configuration) image = [image.imageAsset imageWithConfiguration:configuration];
    if (orig.symbolConfiguration) image = [[image imageWithConfiguration:orig.configuration] imageByApplyingSymbolConfiguration:orig.symbolConfiguration];
    else {
      if (configuration) image = [custom imageWithConfiguration:configuration];
      else image = [custom imageWithConfiguration:orig.configuration];
    }
    //image.neonOrigImage = orig;
    //NSLog(@"NEONDEBUG: %@: %@", orig.imageAsset.assetName, orig.symbolConfiguration);
    //if (orig.symbolConfiguration.scale < 0) image = [image imageOfSize:CGSizeMake(orig.size.width * 2, orig.size.height * 2)];
    return image;
  }
  return custom;
}

%hook _UIAssetManager

%new
- (UIImage *)neonImageNamed:(NSString *)name originalImage:(UIImage *)orig configuration:(id)configuration {
  // the lack of this small obvious check was why i was having a crashing issue with some apps for literally MONTHS lmao
  if (!name) return orig;
  if (name.length > 4 && [[name substringFromIndex:name.length - 4] isEqualToString:@".png"]) name = [name substringToIndex:name.length - 4];
  NSBundle *bundle;
  if (kCFCoreFoundationVersionNumber <= 847.27) bundle = objc_getAssociatedObject(self, &UIKitCarBundle);
  else bundle = self.bundle;
  if (!bundle) bundle = [NSBundle mainBundle];
  if ([bundle.bundlePath rangeOfString:@"NeonCache"].location != NSNotFound) return orig;
  if ([NeonCacheManager isImageNameUnthemed:name bundleID:bundle.bundleIdentifier]) return orig;
  BOOL isTemplate = ([bundle.bundleIdentifier rangeOfString:@"uikit" options:NSCaseInsensitiveSearch].location != NSNotFound || [bundle.bundleIdentifier rangeOfString:@"coreglyphs" options:NSCaseInsensitiveSearch].location != NSNotFound);
  if (UIImage *cachedImage = [NeonCacheManager getCacheImage:name bundleID:bundle.bundleIdentifier]) {
    cachedImage = rescaleImageIfNeeded(cachedImage, orig, name);
    return configureUIImage(cachedImage, orig, configuration, isTemplate);
  }
  if (UIImage *custom = customUIImageWithName(name, bundle, orig)) {
    [NeonCacheManager storeCacheImage:custom name:name bundleID:bundle.bundleIdentifier];
    return configureUIImage(custom, orig, configuration, isTemplate);
  }
  [NeonCacheManager addUnthemedImageName:name bundleID:bundle.bundleIdentifier];
  return orig;
}

%group iOS7
- (instancetype)initWithName:(NSString *)name inBundle:(NSBundle *)bundle idiom:(int)idiom {
  self = %orig;
  if (self) objc_setAssociatedObject(self, &UIKitCarBundle, bundle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  return self;
}
%end

// lazy to do research; just hookin everything i found in the headers lmao
/*- (UIImage *)imageNamed:(NSString *)name {
  return [self neonImageNamed:name originalImage:%orig];
}*/
- (UIImage *)imageNamed:(NSString *)name withTrait:(id)trait {
  return [self neonImageNamed:name originalImage:%orig configuration:nil];
}
- (UIImage *)imageNamed:(NSString *)name idiom:(long long)idiom {
  return [self neonImageNamed:name originalImage:%orig configuration:nil];
}
- (UIImage *)imageNamed:(NSString *)name idiom:(long long)idiom subtype:(unsigned long long)subtype {
  return [self neonImageNamed:name originalImage:%orig configuration:nil];
}
- (UIImage *)imageNamed:(NSString *)name scale:(double)scale idiom:(long long)idiom subtype:(unsigned long long)subtype {
  return [self neonImageNamed:name originalImage:%orig configuration:nil];
}
/*- (UIImage *)imageNamed:(NSString *)name configuration:(id)configuration {
  if (self.managingCoreGlyphs && [glyphNames containsObject:name]) return %orig;
  return [self neonImageNamed:name originalImage:%orig configuration:configuration];
}*/
- (UIImage *)imageNamed:(NSString *)name configuration:(id)configuration cachingOptions:(unsigned long long)cachingOptions attachCatalogImage:(BOOL)attachCatalogImage {
  if (self.managingCoreGlyphs && [glyphNames containsObject:name]) return %orig;
  return [self neonImageNamed:name originalImage:%orig configuration:configuration];
}

%end

@interface CUINamedVectorGlyph
@property (nonatomic, retain) NSString *customPath;
@end

%group iOS13Glyphs

%hook CUINamedVectorGlyph

%property (nonatomic, retain) NSString *customPath;

- (instancetype)initWithName:(NSString *)name scaleFactor:(CGFloat)scaleFactor deviceIdiom:(long long)idiom pointSize:(double)pointSize fromCatalog:(id)catalog usingRenditionKey:(id)usingRenditionKey fromTheme:(unsigned long long)theme {
  self = %orig;
  if (![glyphNames containsObject:name]) return %orig;
  if ([NeonCacheManager isImageNameUnthemed:name bundleID:@"com.apple.CoreGlyphs"]) return self;
  else if (NSString *path = customPathForName(name, [NSBundle bundleWithIdentifier:@"com.apple.CoreGlyphs"])) self.customPath = path;
  else [NeonCacheManager addUnthemedImageName:name bundleID:@"com.apple.CoreGlyphs"];
  return self;
}

- (CGImageRef)image { return [UIImage imageWithContentsOfFile:self.customPath].CGImage ? : %orig; }

%end

%end

%ctor {
  if (kCFCoreFoundationVersionNumber < 847.20) return; // iOS 7 introduced assets
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon) && ![%c(Neon) themes]) return;
  themes = [%c(Neon) themes];
  %init;
  if (kCFCoreFoundationVersionNumber <= 847.27) %init(iOS7);
  if (kCFCoreFoundationVersionNumber >= 1665.15) {
    // this creates a list of images that ios somehow weirdly caches, meaning if we themed them through _UIAssetManager, they would not cache properly and make various apps crash
    // why not just use the CoreUI hook? well it doesn't theme some stuff, and it also messes up scaling by *a lot* sometimes so yeah....
    NSMutableArray *glyphs = [NSMutableArray new];
    for (NSString *glyph in @[@"plus", @"minus", @"ellipsis", @"checkmark", @"camera", @"circle", @"circlebadge"]) for (NSString *format in @[@"", @".fill", @".circle", @".circle.fill"]) [glyphs addObject:[glyph stringByAppendingString:format]];
      [glyphs addObject:@"airplane"];
    glyphNames = [glyphs copy];
    %init(iOS13Glyphs);
  }
}
