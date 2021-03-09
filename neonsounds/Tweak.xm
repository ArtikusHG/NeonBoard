#include <Foundation/Foundation.h>
#include <substrate.h>
#include "../Neon.h"

NSCache *soundPathCache;

bool getCustomFileName(BOOL orig, char *path) {
  if (orig) {
    NSString *newPath = [NSString stringWithUTF8String:path];
    if ([newPath hasPrefix:@"/System/Library/Audio/UISounds/"]) {
      NSString *file = [newPath substringFromIndex:31];
      if (NSString *cachedPath = [soundPathCache objectForKey:file]) {
        if (cachedPath.length == 0) return orig;
        strcpy(path, cachedPath.UTF8String);
        return orig;
      }
      for (NSString *theme in [%c(Neon) themes]) {
        NSString *customPath = [NSString stringWithFormat:@"/Library/Themes/%@/UISounds/%@", theme, file];
        if ([[NSFileManager defaultManager] fileExistsAtPath:customPath]) {
          strcpy(path, customPath.UTF8String);
          [soundPathCache setObject:customPath forKey:file];
          break;
        }
      }
      if (![soundPathCache objectForKey:file]) [soundPathCache setObject:@"" forKey:file];
    }
  }
  return orig;
}

%group hook1 %hookf(bool, func1, unsigned long arg1, char *path, bool &arg3) { return getCustomFileName(%orig(arg1, path, arg3), path); } %end
#ifdef __LP64__
  %group hook2 %hookf(bool, func2, unsigned int arg1, char *path, unsigned int arg3, bool &arg4) { return getCustomFileName(%orig(arg1, path, arg3, arg4), path); } %end
#else
  %group hook3 %hookf(bool, func3, unsigned long arg1, char *path, unsigned long arg3, bool &arg4) { return getCustomFileName(%orig(arg1, path, arg3, arg4);, path); } %end
#endif

%ctor {
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon) && ![%c(Neon) themes]) return;
  soundPathCache = [NSCache new];
  if (MSImageRef image = MSGetImageByName("/System/Library/Frameworks/AudioToolbox.framework/AudioToolbox")) {
    %init(hook1, func1 = MSFindSymbol(image, "__Z24GetFileNameForThisActionmPcRb"));
    #ifdef __LP64__
      %init(hook2, func2 = MSFindSymbol(image, "__Z24GetFileNameForThisActionjPcjRb"));
    #else
      %init(hook3, func3 = MSFindSymbol(image, "__Z24GetFileNameForThisActionmPcmRb"));
    #endif
  }
}
