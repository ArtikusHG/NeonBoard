#ifdef __LP64__

UIImage *thumbImage;
BOOL customImageLoaded = NO;

%hook UISwitchModernVisualElement
+ (UIImage *)_modernThumbImageWithColor:(UIColor *)color mask:(unsigned long long)mask traitCollection:(UITraitCollection *)traitCollection {
  if (!customImageLoaded) {
    thumbImage = [UIImage imageNamed:@"UISwitchKnob"];
    customImageLoaded = YES;
  }
  return thumbImage ? : %orig;
}
%end

%ctor { if (kCFCoreFoundationVersionNumber >= 1665.15) %init; }

#endif
