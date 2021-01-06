#include <Preferences/PSSpecifier.h>
#include "NBPShared.h"
#include "NBPRootListController.h"

@implementation NBPRootListController

- (NSArray *)specifiers {
  if (!_specifiers) _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
  return _specifiers;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  if (![[NSFileManager defaultManager] fileExistsAtPath:@PLIST_PATH_Settings isDirectory:nil]) [[NSFileManager defaultManager] createFileAtPath:@PLIST_PATH_Settings contents:nil attributes:nil];
}

- (void)respring { respring(); }

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
  NSMutableDictionary *prefs = [prefsDict() mutableCopy];
  [prefs setObject:value forKey:[specifier propertyForKey:@"key"]];
  writePrefsDict(prefs);
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
  return prefsDict()[[specifier propertyForKey:@"key"]] ? : NO;
}

- (void)openURLString:(NSString *)urlString {
  NSURL *url = [NSURL URLWithString:urlString];
  if (@available(iOS 10, *)) [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
  else [UIApplication.sharedApplication openURL:url];
}

- (void)twitter {
  [self openURLString:@"https://twitter.com/ArtikusHG"];
}

- (void)github {
  [self openURLString:@"https://github.com/ArtikusHG"];
}

@end
