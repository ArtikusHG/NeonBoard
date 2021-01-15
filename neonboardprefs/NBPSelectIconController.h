#import "PSSearchableListController.h"

@interface NBPSelectIconController : PSListController <UISearchBarDelegate, UIAlertViewDelegate>
@property (nonatomic) BOOL shouldAutoLoadIcons;
@property (nonatomic, retain) NSMutableArray *iconSpecifiers;
@property (nonatomic, retain) NSMutableArray *bundleIDs;
@end
