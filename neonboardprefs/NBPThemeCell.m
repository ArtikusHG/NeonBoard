#include "NBPThemeCell.h"

@implementation NBPThemeCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
  if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier specifier:specifier]) {
    self.detailTextLabel.text = [specifier propertyForKey:@"detailText"];
    return self;
  }
  return nil;
}

- (UILabel *)textLabel {
  UILabel *label = [super textLabel];
  UIColor *color;
  if (@available(iOS 13, *)) color = [UIColor labelColor];
  else color = [UIColor blackColor];
  label.textColor = color;
  label.highlightedTextColor = color;
  return label;
}

- (void)setSelectionStyle:(UITableViewCellSelectionStyle)style { [super setSelectionStyle:UITableViewCellSelectionStyleBlue]; }
- (UITableViewCellSelectionStyle)selectionStyle { return UITableViewCellSelectionStyleBlue; }

@end
