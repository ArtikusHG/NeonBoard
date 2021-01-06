#include <Preferences/PSListController.h>

@interface PSSearchableListController : PSListController <UISearchResultsUpdating, UISearchBarDelegate>
@property (nonatomic, retain) NSMutableArray *originalSpecifiers;
@end
