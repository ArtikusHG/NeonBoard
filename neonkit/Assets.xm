// why this injects into IconServices is something i *do not* know. all i know is that icon masks and a bunch of other stuff don't get applied otherwise????

#include "../Neon.h"
#include "NeonCacheManager.h"

NSArray *themes;
BOOL glyphMode;

static char *UIKitCarBundle;

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
	if ([NeonCacheManager isImageNameUnthemed:name bundleID:bundle.bundleIdentifier]) return orig;
	if (UIImage *cachedImage = [NeonCacheManager getCacheImage:name bundleID:bundle.bundleIdentifier]) {
		if (@available(iOS 13, *)) if (configuration) return [cachedImage imageWithConfiguration:configuration];
		return cachedImage;
	}
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
		for (NSString *imagePath in potentialPaths) {
			if (NSString *path = [%c(Neon) fullPathForImageNamed:name atPath:imagePath]) {
				UIImage *custom = [UIImage imageWithContentsOfFile:path];
				// я люблю костыли)))) (don't mind the russian; this is for the music controls on 13+)
				if ([@[@"backward.fill", @"forward.fill", @"pause.fill", @"play.fill"] containsObject:name] && orig) custom = [custom imageOfSize:orig.size];
				[NeonCacheManager storeCacheImage:custom name:name bundleID:bundle.bundleIdentifier];
				if (@available(iOS 13, *)) if (configuration) return [custom imageWithConfiguration:configuration];
				return custom;
			}
		}
		// newsstand icon on ios 7 & 8 is not from an app; it's a weird custom folder. i make this customize the icon even if it's of new format (ios 9+ where it's an actual app)
		if ([name isEqualToString:@"NewsstandIconEnglish"] || [name isEqualToString:@"NewsstandIconInternational"]) {
			if (NSString *path = [%c(Neon) iconPathForBundleID:@"com.apple.news" fromTheme:theme]) {
				UIImage *custom = [UIImage imageWithContentsOfFile:path];
				[NeonCacheManager storeCacheImage:custom name:name bundleID:bundle.bundleIdentifier];
				return custom;
			}
		}
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

// HIGHLIGHTED TYPE THING???

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
- (UIImage *)imageNamed:(NSString *)name configuration:(id)configuration {
	return [self neonImageNamed:name originalImage:%orig configuration:configuration];
}
- (UIImage *)imageNamed:(NSString *)name idiom:(long long)idiom subtype:(unsigned long long)subtype {
	return [self neonImageNamed:name originalImage:%orig configuration:nil];
}
- (UIImage *)imageNamed:(NSString *)name scale:(double)scale idiom:(long long)idiom subtype:(unsigned long long)subtype {
	return [self neonImageNamed:name originalImage:%orig configuration:nil];
}
- (UIImage *)imageNamed:(NSString *)name configuration:(id)configuration cachingOptions:(id)cachingOptions attachCatalogImage:(BOOL)attachCatalogImage {
	return [self neonImageNamed:name originalImage:%orig configuration:configuration];
}

%end

%ctor {
	if (kCFCoreFoundationVersionNumber < 847.20) return; // iOS 7 introduced assets
	if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon) && ![%c(Neon) themes]) return;
	themes = [%c(Neon) themes];
	%init;
	if (kCFCoreFoundationVersionNumber <= 847.27) %init(iOS7);
}
