#include <Preferences/PSSpecifier.h>
#include "../Neon.h"
#include "PSSearchableListController.h"

@implementation PSSearchableListController

- (void)viewDidLoad {
  [super viewDidLoad];
  if (@available(iOS 8, *)) {
    UISearchController *searchController = [UISearchController new];
    searchController.searchResultsUpdater = self;
    searchController.hidesNavigationBarDuringPresentation = NO;
    searchController.searchBar.delegate = self;
    if (@available(iOS 13, *)) searchController.obscuresBackgroundDuringPresentation = NO;
    else searchController.dimsBackgroundDuringPresentation = NO;
    if (@available(iOS 11, *)) self.navigationItem.searchController = searchController;
    else self.table.tableHeaderView = searchController.searchBar;
  } else {
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    searchBar.delegate = self;
    searchBar.placeholder = @"Search";
    self.table.tableHeaderView = searchBar;
  }
}

- (void)updateSearchResultsWithText:(NSString *)text {
  if (text.length == 0) {
    self.specifiers = self.originalSpecifiers;
    return;
  }
  NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(PSSpecifier *specifier, NSDictionary *bindings) {
    NSString *key = [specifier propertyForKey:@"iconImage"];
    if (key) {
      return [specifier.name.lowercaseString rangeOfString:text.lowercaseString].location != NSNotFound;
    } else {
      return YES;
    }
  }];
  NSMutableArray *_specifiersFiltered = [NSMutableArray new];
  [_specifiersFiltered addObjectsFromArray:self.specifiersInstalledSystemGroup];
  [_specifiersFiltered addObjectsFromArray:self.specifiersInstalledUserGroup];
  [_specifiersFiltered addObjectsFromArray:self.specifiersOffloadedGroup];
  self.specifiers = [[_specifiersFiltered filteredArrayUsingPredicate:predicate] mutableCopy];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)controller {
  [self updateSearchResultsWithText:controller.searchBar.text];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)text {
  [self updateSearchResultsWithText:text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
  self.specifiers = self.originalSpecifiers;
}

@end
