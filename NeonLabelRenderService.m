BOOL fontExists(NSString *fontName) {
  NSArray *families = [UIFont familyNames];
  if ([families containsObject:fontName]) return YES;
  for (NSString *family in families) if ([[UIFont fontNamesForFamilyName:family] containsObject:fontName]) return YES;
    return NO;
}

UIFont *fontWithParams(NSString *fontName, CGFloat size, UIFontWeight weight) {
  return (fontName && fontExists(fontName)) ? [UIFont fontWithName:fontName size:size] : [UIFont systemFontOfSize:size weight:weight];
}
UIFont *fontWithParamsLegacy(NSString *fontName, CGFloat size) {
  return (fontName && fontExists(fontName)) ? [UIFont fontWithName:fontName size:size] : [UIFont systemFontOfSize:size];
}

void drawStringInContextWithSettingsDict(NSString *str, CGContextRef ctx, NSDictionary *dict, CGSize imageSize, UIColor *fallbackColor, BOOL forCalendar, UIFont *defaultFont) {
  if (!str || str.length == 0) return;
  CGFloat proportion = (forCalendar) ? imageSize.width / 60 : 1;
  if ([dict[@"TextCase"] isEqualToString:@"lowercase"]) str = str.lowercaseString;
  else if ([dict[@"TextCase"] isEqualToString:@"uppercase"]) str = str.uppercaseString;
  if (dict[@"TextFormat"] && [dict[@"TextFormat"] isKindOfClass:[NSString class]]) str = [NSString stringWithFormat:dict[@"TextFormat"], str];
  UIFont *font;
  CGFloat fontSize = dict[@"FontSize"] ? [dict[@"FontSize"] floatValue] : defaultFont.pointSize;

  if (!dict[@"FontName"] && defaultFont) font = (fontSize) ? [font fontWithSize:fontSize] : defaultFont;
  else {
    if (@available(iOS 8.2, *)) font = fontWithParams(dict[@"FontName"], fontSize * proportion, UIFontWeightLight);
    else font = fontWithParamsLegacy(dict[@"FontName"] ? : @"HelveticaNeue-UltraLight", fontSize * proportion);
  }
  if (!font) font = [UIFont systemFontOfSize:fontSize];

  CGSize size = [str sizeWithAttributes:@{NSFontAttributeName:font}];
  if (CGSizeEqualToSize(imageSize, CGSizeZero)) imageSize = size; // im lazy :c (4real: this makes the last line of this shit not kill the position when calculating the center.)
  else if (size.width > imageSize.width) {
    str = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
    size = [str sizeWithAttributes:@{NSFontAttributeName:font}];
    // https://stackoverflow.com/questions/14269453/truncate-an-nsstring-to-fit-a-size
    // seriously, i dont wanna spend tons of time working with NSStringDrawingContext just to truncate a string. this small (stolen from stackoverflow) loop works fine for CGContext and a non-attributed string.
    if (size.width > imageSize.width) {
      for (int i = 2; i < str.length; i++) {
        str = [NSString stringWithFormat:@"%@…", [str substringToIndex:str.length - i]];
        size = [str sizeWithAttributes:@{NSFontAttributeName:font}];
        if (size.width <= imageSize.width) break;
      }
    }
  }
  if (size.height != 0) size.height += [dict[@"HeightChange"] floatValue];
  if (size.width != 0) size.width += [dict[@"WidthChange"] floatValue];
  if (size.width == 0 || size.height == 0) return;
  if (!ctx) {
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    ctx = UIGraphicsGetCurrentContext();
  }
  UIColor *textColor = (UIColor *)dict[@"TextColor"] ? : fallbackColor;
  if (dict[@"ShadowColor"]) CGContextSetShadowWithColor(ctx, CGSizeMake([dict[@"ShadowXoffset"] floatValue] * proportion, [dict[@"ShadowYoffset"] floatValue] * proportion), [dict[@"ShadowBlurRadius"] floatValue], [(UIColor *)dict[@"ShadowColor"] CGColor]);
  CGContextSetAlpha(ctx, CGColorGetAlpha(textColor.CGColor));
  CGRect drawRect;
  if (forCalendar) drawRect = CGRectMake([dict[@"TextXoffset"] floatValue] * proportion + ((imageSize.width - size.width) / 2.0f), [dict[@"TextYoffset"] floatValue] * proportion, size.width, size.height);
  else drawRect = CGRectMake([dict[@"TextXoffset"] floatValue] * proportion + ((imageSize.width - size.width) / 2.0f), [dict[@"TextYoffset"] floatValue] * proportion + ((imageSize.height - size.height) / 2.0f), size.width, size.height);
  [str drawInRect:drawRect withAttributes:@{NSFontAttributeName:font, NSForegroundColorAttributeName:textColor}];
}
