#include <Preferences/PSListController.h>

@interface PSEditableListController : PSListController
@end

@interface NBPOverridesController : PSEditableListController <UIAlertViewDelegate>
@property (nonatomic) NSInteger previousOverrideCount;
@end
