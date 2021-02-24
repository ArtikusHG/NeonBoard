#import "PSSearchableListController.h"

@interface NBPSelectIconController : PSListController <UISearchBarDelegate, UIAlertViewDelegate>
@property (nonatomic, retain) NSMutableArray *iconSpecifiers;
@property (nonatomic, retain) NSMutableArray *bundleIDs;
@property (nonatomic, assign) BOOL cancelLoad;
@end
