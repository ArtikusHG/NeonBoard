#import <Preferences/PSListController.h>

@interface PSEditableListController : PSListController
- (UINavigationItem *)_editButtonBarItem;
@end

@interface NBPThemeListController : PSEditableListController
@property (nonatomic, retain) NSMutableDictionary *prefs;
@property (nonatomic, retain) NSMutableArray *allThemes;
@property (nonatomic, retain) NSMutableArray *enabledThemes;
@property (nonatomic, retain) NSMutableArray *allThemesSpecifiers;
@property (nonatomic, retain) NSMutableArray *enabledThemesSpecifiers;
@property (nonatomic) BOOL iconsLoaded;
@end
