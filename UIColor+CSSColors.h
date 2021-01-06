@interface UIColor (CSSColors)
+ (UIColor *)colorWithCSS:(NSString *)cssString;

+ (UIColor *)colorFromHexString:(NSString *)hexString;
+ (UIColor *)colorFromRGBString:(NSString *)rgbString;
+ (UIColor *)colorFromHSLString:(NSString *)hslString;
+ (UIColor *)defaultCSSColorWithString:(NSString *)colorString;
@end
