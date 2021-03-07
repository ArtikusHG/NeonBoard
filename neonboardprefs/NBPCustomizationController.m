#include <Preferences/PSSpecifier.h>
#include "NBPShared.h"
#include "NBPCustomizationController.h"

@implementation NBPCustomizationController

- (NSArray *)specifiers {
  if (!_specifiers) _specifiers = [self loadSpecifiersFromPlistName:@"Customization" target:self];
  return _specifiers;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
  NSMutableDictionary *prefs = [prefsDict() mutableCopy];
  [prefs setObject:value forKey:[specifier propertyForKey:@"key"]];
  writePrefsDict(prefs);
}
- (id)readPreferenceValue:(PSSpecifier*)specifier { return prefsDict()[[specifier propertyForKey:@"key"]] ? : NO; }

@end
