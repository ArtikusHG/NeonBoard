#include <Preferences/PSSpecifier.h>
#include <Preferences/PSTableCell.h>
#include "../Neon.h"
#include "NBPShared.h"
#include "NBPOverridesController.h"

@interface NBPOverrideCell : PSTableCell
@end

@implementation NBPOverrideCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
  if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier specifier:specifier]) {
    self.detailTextLabel.text = [specifier propertyForKey:@"detailText"];
    return self;
  }
  return nil;
}
@end

@implementation NBPOverridesController

NBPOverridesController *sharedInstance;

+ (instancetype)sharedInstance {
  return sharedInstance;
}

- (instancetype)initForContentSize:(CGSize)size {
  if (self = [super initForContentSize:size]) sharedInstance = self;
  return sharedInstance;
}

- (NSArray *)specifiers {
  NSDictionary *dict = [prefsDict() mutableCopy];
  NSDictionary *overrideThemes = dict[@"overrideThemes"];
  if (!_specifiers || (overrideThemes && self.previousOverrideCount && overrideThemes.count != self.previousOverrideCount)) {
    _specifiers = [NSMutableArray new];
    [_specifiers addObject:[PSSpecifier groupSpecifierWithName:@"Add a new override"]];
    [_specifiers addObject:[PSSpecifier preferenceSpecifierNamed:@"Add override" target:self set:nil get:nil detail:NSClassFromString(@"NBPSelectAppController") cell:PSLinkCell edit:nil]];

    if (overrideThemes && [overrideThemes isKindOfClass:[NSDictionary class]] && overrideThemes.count != 0) {
      [_specifiers addObject:[PSSpecifier groupSpecifierWithName:@"Manage overrides"]];
      self.previousOverrideCount = overrideThemes.count;
      for (NSString *key in overrideThemes) {
        LSApplicationProxy *proxy = [NSClassFromString(@"LSApplicationProxy") applicationProxyForIdentifier:key];
        NSString *title = (proxy) ? proxy.localizedName : key;
        PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:title target:self set:nil get:nil detail:nil cell:PSTitleValueCell edit:nil];
        [specifier setProperty:[NBPOverrideCell class] forKey:@"cellClass"];
        NSString *detailText = overrideThemes[key];
        if ([detailText isEqualToString:@"none"]) detailText = @"Unthemed / stock";
        else {
          NSRange range = [detailText rangeOfString:@"/"];
          if (range.location != NSNotFound) {
            NSMutableArray *comps = [[detailText componentsSeparatedByString:@"/"] mutableCopy];
            NSString *theme = comps[0];
            if (theme.length > 6 && [[theme substringFromIndex:theme.length - 6] isEqualToString:@".theme"]) theme = [theme substringToIndex:theme.length - 6];
            [comps replaceObjectAtIndex:0 withObject:theme];
            detailText = [comps componentsJoinedByString:@" : "];
          } else if (detailText.length > 6 && [[detailText substringFromIndex:detailText.length - 6] isEqualToString:@".theme"]) detailText = [detailText substringToIndex:detailText.length - 6];
        }
        [specifier setProperty:detailText forKey:@"detailText"];
        [specifier setProperty:key forKey:@"overrideKey"]; // for deleting
        [_specifiers addObject:specifier];
      }
    }

    [_specifiers addObject:[PSSpecifier groupSpecifierWithName:@"Reset all overrides"]];
    PSSpecifier *reset = [PSSpecifier preferenceSpecifierNamed:@"Reset all overrides" target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
    reset.buttonAction = @selector(resetOverrides);
    [_specifiers addObject:reset];
  }
  return _specifiers;
}

- (void)resetOverrides {
  if (@available(iOS 8, *)) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Really reset overrides?" message:@"This action cannot be undone!" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *resetAction = [UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
      [self actuallyResetOverrides];
    }];
    [alert addAction:cancelAction];
    [alert addAction:resetAction];
    [self presentViewController:alert animated:YES completion:nil];
  } else {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Really reset overrides?" message:@"This action cannot be undone!" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Reset", nil];
    [alert show];
  }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex != alertView.cancelButtonIndex) [self actuallyResetOverrides];
}

- (void)actuallyResetOverrides {
  NSMutableDictionary *dict = [prefsDict() mutableCopy];
  [dict removeObjectForKey:@"overrideThemes"];
  writePrefsDict(dict);
  [self reloadSpecifiers];
}

// swipe to delete should only be allowed on the override cells; we don't want the "Add override" cell deleted.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return [[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[NBPOverrideCell class]];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle != UITableViewCellEditingStyleDelete) return;
  PSTableCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  NSString *key = [cell.specifier propertyForKey:@"overrideKey"];
  if (!key) return;
  NSMutableDictionary *dict = [prefsDict() mutableCopy];
  NSMutableDictionary *overrides = [dict[@"overrideThemes"] mutableCopy];
  [overrides removeObjectForKey:key];
  [dict setObject:overrides forKey:@"overrideThemes"];
  writePrefsDict(dict);
  [super tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
  // 0.4 = approx time of delete animation. reload em to get rid of the manage section if no overrides to manage are left after deletion
  [self performSelector:@selector(reloadSpecifiers) withObject:nil afterDelay:0.4];
}

@end
