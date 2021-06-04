#include "NBPShared.h"
#include "../Neon.h"
#include "NBPThemeCell.h"
#include "NBPThemeListController.h"

NSString *themeNameFromDirectoryName(NSString *themeName) {
  if (themeName.length <= 6) return themeName;
  return ([[themeName substringFromIndex:themeName.length - 6] isEqualToString:@".theme"]) ? [themeName substringToIndex:themeName.length - 6] : themeName;
}

@interface NSMutableArray (Neon)
- (void)moveObjectFromIndex:(NSUInteger)source toIndex:(NSUInteger)dest;
@end
@implementation NSMutableArray (Neon)
- (void)moveObjectFromIndex:(NSUInteger)source toIndex:(NSUInteger)dest {
  id obj = [self objectAtIndex:source];
  [self removeObjectAtIndex:source];
  [self insertObject:obj atIndex:dest];
}
@end

@implementation NBPThemeListController

@synthesize enabledThemes;
@synthesize enabledThemesSpecifiers;
@synthesize allThemesSpecifiers;
@synthesize prefs;

- (UINavigationItem *)_editButtonBarItem {
  UINavigationItem *item = [super _editButtonBarItem];
  if ([item.title isEqualToString:@"Edit"]) item.title = @"Sort";
  return item;
}

- (PSSpecifier *)themeSpecifierWithTheme:(NSString *)theme {
  PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:themeNameFromDirectoryName(theme) target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
  [specifier setProperty:[NBPThemeCell class] forKey:@"cellClass"];
  NSString *themePath = [NSString stringWithFormat:@"/Library/Themes/%@/", theme];
  [specifier setProperty:themePath forKey:@"themePath"];
  [specifier setProperty:theme forKey:@"themeName"];
  NSMutableArray *themeIcons = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[themePath stringByAppendingPathComponent:@"IconBundles"] error:nil] mutableCopy];
  [themeIcons removeObject:@"Icon.png"];
  [themeIcons removeObject:@"icon.png"];
  [specifier setProperty:[NSString stringWithFormat:@"%lu icons", (unsigned long)themeIcons.count] forKey:@"detailText"];
  [specifier setProperty:@65 forKey:@"height"];
  return specifier;
}

- (NSArray *)specifiers {
  if (!_specifiers) {
    if (!NSClassFromString(@"Neon")) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
    _specifiers = [NSMutableArray new];
    if (!prefs) prefs = [prefsDict() mutableCopy];
    if (!enabledThemes) enabledThemes = [[prefs objectForKey:@"enabledThemes"] mutableCopy] ? : [NSMutableArray new];

    NSMutableArray *allThemes = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/Themes" error:nil] mutableCopy];
    [allThemes removeObject:@".NeonRenderCache"];
    if (!enabledThemesSpecifiers) {
      enabledThemesSpecifiers = [NSMutableArray new];
      for (NSString *theme in enabledThemes) {
        [allThemes removeObject:theme];
        PSSpecifier *specifier = [self themeSpecifierWithTheme:theme];
        specifier.cellType = PSTitleValueCell;
        [enabledThemesSpecifiers addObject:specifier];
      }
    }
    [_specifiers addObject:[PSSpecifier groupSpecifierWithName:@"Enabled themes"]];
    [_specifiers addObjectsFromArray:enabledThemesSpecifiers];

    if (!allThemesSpecifiers) {
      allThemesSpecifiers = [NSMutableArray new];
      for (NSString *theme in allThemes) {
        PSSpecifier *specifier = [self themeSpecifierWithTheme:theme];
        [allThemesSpecifiers addObject:specifier];
      }
    }
    [allThemesSpecifiers sortUsingComparator:^NSComparisonResult(PSSpecifier *a, PSSpecifier *b) {
      return [a.name localizedCaseInsensitiveCompare:b.name];
    }];
    [_specifiers addObject:[PSSpecifier groupSpecifierWithName:@"All themes"]];
    [_specifiers addObjectsFromArray:allThemesSpecifiers];

    if (self.iconsLoaded) return _specifiers;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      // shitty way to do it that's first. second idk why do i have to tell it the icons are loaded BEFORE THEY ARE EVEN LOADED but there was an issue with icons and after moving this line here (it was at the end of the loop) i can't reproduce it so i'll assume it's fixed
      self.iconsLoaded = YES;
      for (PSSpecifier *specifier in _specifiers) {
        if (specifier.cellType == PSGroupCell) continue;
        NSString *themePath = [specifier propertyForKey:@"themePath"];
        NSArray *names = @[@"Icon.png", @"icon.png", @"IconBundles/Icon.png", @"IconBundles/icon.png"];
        UIImage *icon;
        for (NSString *name in names) {
          NSString *path = [themePath stringByAppendingPathComponent:name];
          if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            icon = [UIImage imageWithContentsOfFile:path];
            break;
          }
        }
        NSString *theme = [specifier propertyForKey:@"themeName"];
        if (!icon && NSClassFromString(@"Neon")) icon = [UIImage imageWithContentsOfFile:[NSClassFromString(@"Neon") iconPathForBundleID:@"com.apple.mobilephone" fromTheme:theme]];
        if (!icon) icon = [UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/neonboardprefs.bundle/Theme.png"];
        if (icon) {
          icon = iconForCellFromIcon(icon, CGSizeMake(55, 55));
          [specifier setProperty:icon forKey:@"iconImage"];
          dispatch_async(dispatch_get_main_queue(), ^{
            [self.table reloadData];
          });
        }
        [specifier removePropertyForKey:@"themePath"];
      }
    });
  }
  return _specifiers;
}

- (void)saveData {
  [prefs setObject:enabledThemes forKey:@"enabledThemes"];
  writePrefsDict(prefs);
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath { return UITableViewCellEditingStyleNone; }
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath { return (indexPath.section == 0); }
- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath { return NO; }

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
  if (sourceIndexPath.section != destinationIndexPath.section || sourceIndexPath.section != 0) return;
  [enabledThemes moveObjectFromIndex:sourceIndexPath.row toIndex:destinationIndexPath.row];
  [enabledThemesSpecifiers moveObjectFromIndex:sourceIndexPath.row toIndex:destinationIndexPath.row];
  [self reloadSpecifiers];
  [self saveData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == 0) {
    [enabledThemes removeObjectAtIndex:indexPath.row];
    PSSpecifier *specifier = [enabledThemesSpecifiers objectAtIndex:indexPath.row];
    specifier.cellType = PSButtonCell;
    [allThemesSpecifiers addObject:specifier];
    [enabledThemesSpecifiers removeObjectAtIndex:indexPath.row];
  } else {
    PSSpecifier *specifier = [(PSTableCell *)[tableView cellForRowAtIndexPath:indexPath] specifier];
    specifier.cellType = PSTitleValueCell;
    [enabledThemes insertObject:[specifier propertyForKey:@"themeName"] atIndex:0];
    [enabledThemesSpecifiers insertObject:[allThemesSpecifiers objectAtIndex:indexPath.row] atIndex:0];
    [allThemesSpecifiers removeObjectAtIndex:indexPath.row];
  }
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  [self reloadSpecifiers];
  [self saveData];
}

@end
