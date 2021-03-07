#include <Preferences/PSSpecifier.h>
#include "../Neon.h"
#include "NBPSelectAppController.h"

@implementation NBPSelectAppController

- (NSString *)title { return @"Select app"; }

- (NSArray *)specifiers {
  if (!_specifiers) {
    // TODO: complete this list.
    NSArray *internalApps = [NSArray arrayWithContentsOfFile:@"/Library/PreferenceBundles/neonboardprefs.bundle/InternalApps.plist"];
    _specifiers = [NSMutableArray new];
    NSMutableArray *_specifiersInstalledSystemGroup = [NSMutableArray new];
    NSMutableArray *_specifiersInstalledSystemApps = [NSMutableArray new];
    NSMutableArray *_specifiersInstalledUserGroup = [NSMutableArray new];
    NSMutableArray *_specifiersInstalledUserApps = [NSMutableArray new];
    NSMutableArray *_specifiersOffloadedGroup = [NSMutableArray new];
    NSMutableArray *_specifiersOffloadedApps = [NSMutableArray new];

    // ugly, but much simpler way of getting the default icon
    UIImage *defaultIcon = [UIImage _applicationIconImageForBundleIdentifier:@"com.apple.DemoApp" format:0 scale:[UIScreen mainScreen].scale];
    for (LSApplicationProxy *proxy in [[NSClassFromString(@"LSApplicationWorkspace") defaultWorkspace] allApplications]) {
      if ([internalApps containsObject:proxy.applicationIdentifier]) continue;
      // if ( proxy.isRestricted ) continue;

      NSString *title = proxy.localizedName;
      // old versions (e.g. ios 7 don't get localizedName as an empty string for some reason :/)
      if (!title || title.length == 0) {
        NSBundle *bundle = [NSBundle bundleWithURL:proxy.bundleURL];
        title = bundle.infoDictionary[@"CFBundleName"] ? : bundle.infoDictionary[@"CFBundleExecutable"];
      }
      if ( [proxy.applicationIdentifier isEqualToString:@"com.apple.CarPlaySettings"] ) {
        title = [title stringByAppendingString:@" - CarPlay"];
      }
      PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:title target:self set:nil get:nil detail:NSClassFromString(@"NBPSelectThemeController") cell:PSLinkCell edit:nil];
      [specifier setProperty:defaultIcon forKey:@"iconImage"];
      [specifier setProperty:proxy.applicationIdentifier forKey:@"appBundleID"];
      bool isInstalled = proxy.isInstalled;
      bool isSystemApp = NO;
      if ( [proxy.applicationType isEqualToString:@"System"] ) {
        isSystemApp = YES;
      }

      if ( isInstalled && isSystemApp ) {
        [_specifiersInstalledSystemApps addObject:specifier];
      } else if ( isInstalled && !isSystemApp ) {
        [_specifiersInstalledUserApps addObject:specifier];
      } else if ( !isInstalled ) {
        [_specifiersOffloadedApps addObject:specifier];
      }
    }
    if ( [_specifiersInstalledSystemApps count] > 0) {
      [_specifiersInstalledSystemGroup addObject:[PSSpecifier groupSpecifierWithName:@"System Apps"]];
      [_specifiersInstalledSystemApps sortUsingComparator:^NSComparisonResult(PSSpecifier *a, PSSpecifier *b) {
        return [a.name localizedCaseInsensitiveCompare:b.name];
      }];
      [_specifiersInstalledSystemGroup addObjectsFromArray:_specifiersInstalledSystemApps];
      self.specifiersInstalledSystemGroup = [_specifiersInstalledSystemGroup mutableCopy];
      [_specifiers addObjectsFromArray:_specifiersInstalledSystemGroup];
    }

    if ( [_specifiersInstalledUserApps count] > 0) {
      [_specifiersInstalledUserGroup addObject:[PSSpecifier groupSpecifierWithName:@"User Apps"]];
      [_specifiersInstalledUserApps sortUsingComparator:^NSComparisonResult(PSSpecifier *a, PSSpecifier *b) {
        return [a.name localizedCaseInsensitiveCompare:b.name];
      }];
      [_specifiersInstalledUserGroup addObjectsFromArray:_specifiersInstalledUserApps];
      self.specifiersInstalledUserGroup = [_specifiersInstalledUserGroup mutableCopy];
      [_specifiers addObjectsFromArray:_specifiersInstalledUserGroup];
    }

    if ( [_specifiersOffloadedApps count] > 0) {
      [_specifiersOffloadedGroup addObject:[PSSpecifier groupSpecifierWithName:@"Offloaded Apps"]];
      [_specifiersOffloadedApps sortUsingComparator:^NSComparisonResult(PSSpecifier *a, PSSpecifier *b) {
        return [a.name localizedCaseInsensitiveCompare:b.name];
      }];
      [_specifiersOffloadedGroup addObjectsFromArray:_specifiersOffloadedApps];
      self.specifiersOffloadedGroup = [_specifiersOffloadedGroup mutableCopy];
      [_specifiers addObjectsFromArray:_specifiersOffloadedGroup];
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      for (PSSpecifier *specifier in _specifiers) {
        [specifier setProperty:[UIImage _applicationIconImageForBundleIdentifier:[specifier propertyForKey:@"appBundleID"] format:0 scale:[UIScreen mainScreen].scale] forKey:@"iconImage"];
        dispatch_async(dispatch_get_main_queue(), ^{
          [[specifier propertyForKey:@"cellObject"] refreshCellContentsWithSpecifier:specifier];
        });
      }
    });
    self.originalSpecifiers = [_specifiers mutableCopy];
  }
  return _specifiers;
}

@end
