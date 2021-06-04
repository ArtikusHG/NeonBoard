#include "../Neon.h"
#include "NBPShared.h"
#include "NBPThemeCell.h"
#include "NBPSelectThemeController.h"

NSString *themeNameFromDirectoryName(NSString *themeName);

@implementation NBPSelectThemeController

- (NSString *)title { return @"Select theme"; }

- (NSArray *)specifiers {
  if (!_specifiers) {
    // load NeonEngine just in case
    if (!NSClassFromString(@"Neon")) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
    if (!NSClassFromString(@"Neon")) return _specifiers;
    _specifiers = [NSMutableArray new];

    for (NSString *theme in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/Themes/" error:nil]) {
      if ([theme isEqualToString:@".NeonRenderCache"]) continue;
      NSString *themePath = [NSString stringWithFormat:@"/Library/Themes/%@/IconBundles", theme];
      if ([[NSFileManager defaultManager] fileExistsAtPath:themePath]) {
        // we check if the only thing in IconBundles is Icon.png (or icon.png, same but lowercase), the one provided to be displayed in the pref bundle, but not an actual app icon, to avoid listing useless themes
        NSSet *contentsSet = [NSSet setWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:themePath error:nil]];
        if ([contentsSet isEqualToSet:[NSSet setWithArray:@[@"Icon.png"]]] || [contentsSet isEqualToSet:[NSSet setWithArray:@[@"icon.png"]]]) continue;

        NSString *title = themeNameFromDirectoryName(theme);
        //if ([[title substringFromIndex:title.length - 6] isEqualToString:@".theme"]) title = [title substringToIndex:title.length - 6];
        PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:title target:self set:nil get:nil detail:NSClassFromString(@"NBPSelectIconController") cell:PSLinkCell edit:nil];
        [specifier setProperty:[NBPThemeCell class] forKey:@"cellClass"];

        NSMutableArray *themeIcons = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:themePath error:nil] mutableCopy];
        [themeIcons removeObject:@"Icon.png"];
        [themeIcons removeObject:@"icon.png"];
        [specifier setProperty:[NSString stringWithFormat:@"%lu icons", (unsigned long)themeIcons.count] forKey:@"detailText"];

        [specifier setProperty:[self.specifier propertyForKey:@"appBundleID"] forKey:@"appBundleID"];
        [specifier setProperty:theme forKey:@"themeName"];
        [specifier setProperty:themePath forKey:@"themePath"];
        [specifier setProperty:@65 forKey:@"height"];
        [_specifiers addObject:specifier];
      }
    }
    [_specifiers sortUsingComparator:^NSComparisonResult(PSSpecifier *a, PSSpecifier *b) {
      return [a.name localizedCaseInsensitiveCompare:b.name];
    }];
    // unthemed
    PSSpecifier *unthemed = [PSSpecifier preferenceSpecifierNamed:@"Unthemed / stock" target:self set:nil get:nil detail:NSClassFromString(@"NBPSelectIconController") cell:PSLinkCell edit:nil];
    [unthemed setProperty:[NBPThemeCell class] forKey:@"cellClass"];
    [unthemed setProperty:@"Unthemed icon" forKey:@"detailText"];
    [unthemed setProperty:@"none" forKey:@"themeName"];
    [unthemed setProperty:[self.specifier propertyForKey:@"appBundleID"] forKey:@"appBundleID"];
    [unthemed setProperty:@65 forKey:@"height"];
    [_specifiers insertObject:unthemed atIndex:0];
    self.originalSpecifiers = [_specifiers mutableCopy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      for (PSSpecifier *specifier in _specifiers) {
        // this is turning into a mess and i can't stop that, so i decided to at least explain the logic
        // we look for the Icon.png of the theme. it (appears that it) can be: Icon.png, icon.png, IconBundles/Icon.png, IconBundles/icon.png
        // we add these paths to an array. then we insert the app icon's path if it exists at the 0 index, so that the app icon is being used above the Icon.png (e.g. if both app icon and Icon.png exist, app icon will be used)
        // then, we assign the icon to an UIImage. if it's an appIcon, we assign it to @"thisIcon" of specifier to load it in SelectIconController
        // and then, we add it to the specifier's icon anyway.
        // hopefully artikus from the future will understand this code (or, even better, it will never break and there will be no need to understand it again)
        // to future self: just in case, i'm sorry
        NSString *themePath = [specifier propertyForKey:@"themePath"];
        UIImage *icon;
        if (!themePath) {
          // icon
          LSApplicationProxy *proxy = [NSClassFromString(@"LSApplicationProxy") applicationProxyForIdentifier:[self.specifier propertyForKey:@"appBundleID"]];
          if (proxy) {
            NSBundle *bundle = [NSBundle bundleWithURL:proxy.bundleURL];
            NSArray *iconFiles = bundle.infoDictionary[@"CFBundleIcons"][@"CFBundlePrimaryIcon"][@"CFBundleIconFiles"] ? : bundle.infoDictionary[@"CFBundleIconFiles"];
            if (!iconFiles && bundle.infoDictionary[@"CFBundleIconFile"]) iconFiles = @[bundle.infoDictionary[@"CFBundleIconFile"]];
            if ([iconFiles isKindOfClass:[NSArray class]]) icon = [UIImage imageNamed:[iconFiles lastObject] inBundle:bundle];
            [[NSString stringWithFormat:@"%@",bundle] writeToFile:@"/var/mobile/a" atomically:YES encoding:NSUTF8StringEncoding error:nil];
          }
          if (!icon) icon = [UIImage imageNamed:@"DefaultIcon-60" inBundle:[NSBundle bundleWithIdentifier:@"com.apple.mobileicons.framework"]];
          icon = iconForCellFromIcon(icon, CGSizeMake(55, 55));
          [specifier setProperty:icon forKey:@"thisIcon"];
        } else {
          NSMutableArray *iconPaths = [@[
            [themePath stringByAppendingPathComponent:@"Icon.png"],
            [themePath stringByAppendingPathComponent:@"icon.png"],
            [[themePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Icon.png"],
            [[themePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"icon.png"]
            ] mutableCopy];
          NSString *appIconPath = [NSClassFromString(@"Neon") iconPathForBundleID:[self.specifier propertyForKey:@"appBundleID"] fromTheme:[specifier propertyForKey:@"themeName"]];
          if (appIconPath) [iconPaths insertObject:appIconPath atIndex:0];
          for (NSString *iconPath in iconPaths) if ((icon = [UIImage imageWithContentsOfFile:iconPath])) break;
            if (icon) {
              icon = iconForCellFromIcon(icon, CGSizeMake(55, 55));
            if (appIconPath) [specifier setProperty:icon forKey:@"thisIcon"]; // pass the icon to avoid loading it again when picking for selected app and of selected app im very good at explaining ik
          } else {
            icon = [UIImage imageNamed:@"DefaultIcon-60" inBundle:[NSBundle bundleWithIdentifier:@"com.apple.mobileicons.framework"]];
            icon = iconForCellFromIcon(icon, CGSizeMake(55, 55));
          }
        }
        [specifier setProperty:icon forKey:@"iconImage"];
        dispatch_async(dispatch_get_main_queue(), ^{
          [self.table reloadData];
        });
      }
    });
  }
  return _specifiers;
}

@end
