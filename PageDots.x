#include "Neon.h"

NSString *basePath;

%group Dots

%hook SBIconListPageControl

UIImage *dot;
UIImage *currentDot;

- (UIImage *)_iconListIndicatorImage:(BOOL)enabled { return ((enabled) ? currentDot : dot) ? : %orig; }

- (instancetype)initWithFrame:(CGRect)frame {
  dot = [UIImage imageWithContentsOfFile:[%c(Neon) fullPathForImageNamed:@"Dot_PagesSB" atPath:basePath]];
  if (!dot) dot = [UIImage imageWithContentsOfFile:[%c(Neon) fullPathForImageNamed:@"Dot_Pages" atPath:basePath]];
  currentDot = [UIImage imageWithContentsOfFile:[%c(Neon) fullPathForImageNamed:@"Dot_CurrentSB" atPath:basePath]];
  if (!currentDot) currentDot = [UIImage imageWithContentsOfFile:[%c(Neon) fullPathForImageNamed:@"Dot_Current" atPath:basePath]];
  return %orig;
}

%end

%end

%group iOS14
%hook _UIInteractivePageControlVisualProvider
- (UIImage *)indicatorImageForPage:(NSInteger)page { return dot; }
%end
%end

%ctor {
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon) || ![%c(Neon) themes]) return;
  NSMutableArray *mutableThemes = [[%c(Neon) themes] mutableCopy] ? : [NSMutableArray new];
  for (int i = mutableThemes.count - 1; i >= 0; i--) {
    NSString *path1 = [NSString stringWithFormat:@"/Library/Themes/%@/ANEMPageDots", [mutableThemes objectAtIndex:i]];
    NSString *path2 = [NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.magicdots.images", [mutableThemes objectAtIndex:i]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path1 isDirectory:nil] || [[NSFileManager defaultManager] fileExistsAtPath:path2 isDirectory:nil]) continue;
    else [mutableThemes removeObjectAtIndex:i];
  }
  if (mutableThemes && mutableThemes.count > 0) {
    for (NSString *theme in mutableThemes) {
      for (NSString *folder in @[@"ANEMPageDots", @"Bundles/com.magicdots.images"]) {
        basePath = [NSString stringWithFormat:@"/Library/Themes/%@/%@/", theme, folder];
        if ([[NSFileManager defaultManager] fileExistsAtPath:basePath isDirectory:nil]) break;
      }
      if (basePath) break;
    }
    %init(Dots);
    if (kCFCoreFoundationVersionNumber >= 1740) %init(iOS14);
  }
}
