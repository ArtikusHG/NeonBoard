@implementation UIColor (CSSColors)

+ (UIColor *)colorWithCSS:(NSString *)cssString {
  if (!cssString || cssString.length == 0) return nil;
  if ([[cssString substringToIndex:1] isEqualToString:@"#"]) return [self colorFromHexString:cssString];
  if ([[cssString substringToIndex:3] isEqualToString:@"rgb"]) return [self colorFromRGBString:cssString];
  if ([[cssString substringToIndex:3] isEqualToString:@"hsl"]) return [self colorFromHSLString:cssString];
  return [self defaultCSSColorWithString:cssString];
}

// https://stackoverflow.com/questions/1560081/how-can-i-create-a-uicolor-from-a-hex-string
+ (UIColor *)colorFromHexString:(NSString *)hexString {
  unsigned rgbValue = 0;
  NSScanner *scanner = [NSScanner scannerWithString:hexString];
  [scanner setScanLocation:1];
  [scanner scanHexInt:&rgbValue];
  return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0 green:((rgbValue & 0xFF00) >> 8) / 255.0 blue:(rgbValue & 0xFF) / 255.0 alpha:1.0];
}

+ (NSArray *)separateArgumentsFromFunctionString:(NSString *)string forRGB:(BOOL)doPercent {
  if ([string rangeOfString:@"("].location == NSNotFound || [string rangeOfString:@")"].location == NSNotFound || [string rangeOfString:@","].location == NSNotFound) return nil;
  string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
  string = [string substringFromIndex:[string rangeOfString:@"("].location + 1];
  string = [string substringToIndex:[string rangeOfString:@")"].location];
  NSArray *stringValues = [string componentsSeparatedByString:@","];
  NSMutableArray *values = [NSMutableArray new];
  for (NSString *str in stringValues) {
    if (doPercent && [str rangeOfString:@"%"].location != NSNotFound) {
      CGFloat percentage = [[str substringToIndex:str.length - 1] floatValue];
      [values addObject:[NSNumber numberWithFloat:2.55 * percentage]];
    } else [values addObject:[NSNumber numberWithFloat:[str floatValue]]];
  }
  return [values copy];
}

+ (UIColor *)colorFromRGBString:(NSString *)rgbString {
  NSArray *rgbValues = [self separateArgumentsFromFunctionString:rgbString forRGB:YES];
  if (rgbValues.count < 3) return [UIColor blackColor];
  return [UIColor colorWithRed:[rgbValues[0] floatValue] green:[rgbValues[1] floatValue] blue:[rgbValues[2] floatValue] alpha:(rgbValues.count == 4) ? [rgbValues[3] floatValue] : 1.0];
}

+ (UIColor *)colorFromHSLString:(NSString *)hslString {
  NSArray *hslValues = [self separateArgumentsFromFunctionString:hslString forRGB:NO];
  if (hslValues.count < 3) return [UIColor blackColor];
  // yes. 360.001. change to 360 yourself and check if you don't believe lol, it resets to 0 when hslValues[0] is 360 & i don't give a shit about hsl so i won't debug it
  return [UIColor colorWithHue:[hslValues[0] floatValue] / 360.001 saturation:[hslValues[1] floatValue] / 100 brightness:[hslValues[2] floatValue] / 100 alpha:(hslValues.count == 4) ? [hslValues[3] floatValue] : 1.0];
}

+ (NSDictionary *)cssColors {
  return @{
    @"AliceBlue" : @"#F0F8FF",
    @"AntiqueWhite" : @"#FAEBD7",
    @"Aqua" : @"#00FFFF",
    @"Aquamarine" : @"#7FFFD4",
    @"Azure" : @"#F0FFFF",
    @"Beige" : @"#F5F5DC",
    @"Bisque" : @"#FFE4C4",
    @"Black" : @"#000000",
    @"BlanchedAlmond" : @"#FFEBCD",
    @"Blue" : @"#0000FF",
    @"BlueViolet" : @"#8A2BE2",
    @"Brown" : @"#A52A2A",
    @"BurlyWood" : @"#DEB887",
    @"CadetBlue" : @"#5F9EA0",
    @"Chartreuse" : @"#7FFF00",
    @"Chocolate" : @"#D2691E",
    @"Coral" : @"#FF7F50",
    @"CornflowerBlue" : @"#6495ED",
    @"Cornsilk" : @"#FFF8DC",
    @"Crimson" : @"#DC143C",
    @"Cyan" : @"#00FFFF",
    @"DarkBlue" : @"#00008B",
    @"DarkCyan" : @"#008B8B",
    @"DarkGoldenRod" : @"#B8860B",
    @"DarkGray" : @"#A9A9A9",
    @"DarkGrey" : @"#A9A9A9",
    @"DarkGreen" : @"#006400",
    @"DarkKhaki" : @"#BDB76B",
    @"DarkMagenta" : @"#8B008B",
    @"DarkOliveGreen" : @"#556B2F",
    @"DarkOrange" : @"#FF8C00",
    @"DarkOrchid" : @"#9932CC",
    @"DarkRed" : @"#8B0000",
    @"DarkSalmon" : @"#E9967A",
    @"DarkSeaGreen" : @"#8FBC8F",
    @"DarkSlateBlue" : @"#483D8B",
    @"DarkSlateGray" : @"#2F4F4F",
    @"DarkSlateGrey" : @"#2F4F4F",
    @"DarkTurquoise" : @"#00CED1",
    @"DarkViolet" : @"#9400D3",
    @"DeepPink" : @"#FF1493",
    @"DeepSkyBlue" : @"#00BFFF",
    @"DimGray" : @"#696969",
    @"DimGrey" : @"#696969",
    @"DodgerBlue" : @"#1E90FF",
    @"FireBrick" : @"#B22222",
    @"FloralWhite" : @"#FFFAF0",
    @"ForestGreen" : @"#228B22",
    @"Fuchsia" : @"#FF00FF",
    @"Gainsboro" : @"#DCDCDC",
    @"GhostWhite" : @"#F8F8FF",
    @"Gold" : @"#FFD700",
    @"GoldenRod" : @"#DAA520",
    @"Gray" : @"#808080",
    @"Grey" : @"#808080",
    @"Green" : @"#008000",
    @"GreenYellow" : @"#ADFF2F",
    @"HoneyDew" : @"#F0FFF0",
    @"HotPink" : @"#FF69B4",
    @"IndianRed" : @"#CD5C5C",
    @"Indigo" : @"#4B0082",
    @"Ivory" : @"#FFFFF0",
    @"Khaki" : @"#F0E68C",
    @"Lavender" : @"#E6E6FA",
    @"LavenderBlush" : @"#FFF0F5",
    @"LawnGreen" : @"#7CFC00",
    @"LemonChiffon" : @"#FFFACD",
    @"LightBlue" : @"#ADD8E6",
    @"LightCoral" : @"#F08080",
    @"LightCyan" : @"#E0FFFF",
    @"LightGoldenRodYellow" : @"#FAFAD2",
    @"LightGray" : @"#D3D3D3",
    @"LightGrey" : @"#D3D3D3",
    @"LightGreen" : @"#90EE90",
    @"LightPink" : @"#FFB6C1",
    @"LightSalmon" : @"#FFA07A",
    @"LightSeaGreen" : @"#20B2AA",
    @"LightSkyBlue" : @"#87CEFA",
    @"LightSlateGray" : @"#778899",
    @"LightSlateGrey" : @"#778899",
    @"LightSteelBlue" : @"#B0C4DE",
    @"LightYellow" : @"#FFFFE0",
    @"Lime" : @"#00FF00",
    @"LimeGreen" : @"#32CD32",
    @"Linen" : @"#FAF0E6",
    @"Magenta" : @"#FF00FF",
    @"Maroon" : @"#800000",
    @"MediumAquaMarine" : @"#66CDAA",
    @"MediumBlue" : @"#0000CD",
    @"MediumOrchid" : @"#BA55D3",
    @"MediumPurple" : @"#9370DB",
    @"MediumSeaGreen" : @"#3CB371",
    @"MediumSlateBlue" : @"#7B68EE",
    @"MediumSpringGreen" : @"#00FA9A",
    @"MediumTurquoise" : @"#48D1CC",
    @"MediumVioletRed" : @"#C71585",
    @"MidnightBlue" : @"#191970",
    @"MintCream" : @"#F5FFFA",
    @"MistyRose" : @"#FFE4E1",
    @"Moccasin" : @"#FFE4B5",
    @"NavajoWhite" : @"#FFDEAD",
    @"Navy" : @"#000080",
    @"OldLace" : @"#FDF5E6",
    @"Olive" : @"#808000",
    @"OliveDrab" : @"#6B8E23",
    @"Orange" : @"#FFA500",
    @"OrangeRed" : @"#FF4500",
    @"Orchid" : @"#DA70D6",
    @"PaleGoldenRod" : @"#EEE8AA",
    @"PaleGreen" : @"#98FB98",
    @"PaleTurquoise" : @"#AFEEEE",
    @"PaleVioletRed" : @"#DB7093",
    @"PapayaWhip" : @"#FFEFD5",
    @"PeachPuff" : @"#FFDAB9",
    @"Peru" : @"#CD853F",
    @"Pink" : @"#FFC0CB",
    @"Plum" : @"#DDA0DD",
    @"PowderBlue" : @"#B0E0E6",
    @"Purple" : @"#800080",
    @"RebeccaPurple": @"#663399",
    @"Red" : @"#FF0000",
    @"RosyBrown" : @"#BC8F8F",
    @"RoyalBlue" : @"#4169E1",
    @"SaddleBrown" : @"#8B4513",
    @"Salmon" : @"#FA8072",
    @"SandyBrown" : @"#F4A460",
    @"SeaGreen" : @"#2E8B57",
    @"SeaShell" : @"#FFF5EE",
    @"Sienna" : @"#A0522D",
    @"Silver" : @"#C0C0C0",
    @"SkyBlue" : @"#87CEEB",
    @"SlateBlue" : @"#6A5ACD",
    @"SlateGray" : @"#708090",
    @"SlateGrey" : @"#708090",
    @"Snow" : @"#FFFAFA",
    @"SpringGreen" : @"#00FF7F",
    @"SteelBlue" : @"#4682B4",
    @"Tan" : @"#D2B48C",
    @"Teal" : @"#008080",
    @"Thistle" : @"#D8BFD8",
    @"Tomato" : @"#FF6347",
    @"Turquoise" : @"#40E0D0",
    @"Violet" : @"#EE82EE",
    @"Wheat" : @"#F5DEB3",
    @"White" : @"#FFFFFF",
    @"WhiteSmoke" : @"#F5F5F5",
    @"Yellow" : @"#FFFF00",
    @"YellowGreen" : @"#9ACD32",
    @"transparent": @"#0000"
  };
}

+ (UIColor *)defaultCSSColorWithString:(NSString *)colorString {
  for (NSString *key in [self cssColors].allKeys) if ([[key lowercaseString] isEqualToString:[colorString lowercaseString]]) return [self colorFromHexString:[[self cssColors] objectForKey:key]];
    return [UIColor blackColor];
}

@end
