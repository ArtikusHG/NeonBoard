#include <Preferences/PSListController.h>

@interface PSSearchableListController : PSListController <UISearchResultsUpdating, UISearchBarDelegate>
@property (nonatomic, retain) NSMutableArray *originalSpecifiers;
@property (nonatomic, retain) NSMutableArray *specifiersInstalledSystemGroup;
@property (nonatomic, retain) NSMutableArray *specifiersInstalledUserGroup;
@property (nonatomic, retain) NSMutableArray *specifiersOffloadedGroup;
@end
