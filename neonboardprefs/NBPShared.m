#include <spawn.h>
#include <signal.h>
#include <AppSupport/CPDistributedMessagingCenter.h>
#include "../Neon.h"
#include "NBPShared.h"

NSDictionary *prefsDict() {
  if (@available(iOS 11, *)) return [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:@PLIST_PATH_Settings] error:nil] ? : [NSDictionary dictionary];
  return [NSDictionary dictionaryWithContentsOfFile:@PLIST_PATH_Settings] ? : [NSDictionary dictionary];
}

void writePrefsDict(NSDictionary *dict) {
  if (@available(iOS 11, *)) [dict writeToURL:[NSURL fileURLWithPath:@PLIST_PATH_Settings] error:nil];
  else [dict writeToFile:@PLIST_PATH_Settings atomically:YES];
}

UIImage *iconForCellFromIcon(UIImage *icon, CGSize size) {
  UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
  CGContextClipToMask(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, size.width, size.height), [NSClassFromString(@"Neon") getMaskImage].CGImage);
  [icon drawInRect:CGRectMake(0, 0, size.width, size.height)];
  UIImage *newIcon = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return newIcon;
}

void respring() {
  [[NSFileManager defaultManager] removeItemAtPath:[NSClassFromString(@"Neon") renderDir] error:nil];
  [[NSFileManager defaultManager] createDirectoryAtPath:[NSClassFromString(@"Neon") renderDir] withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions: @0777} error:nil];

  [[NSFileManager defaultManager] removeItemAtPath:@cacheDir error:nil];
  [[NSFileManager defaultManager] removeItemAtPath:@"/var/containers/Shared/SystemGroup/systemgroup.com.apple.lsd.iconscache/Library/Caches/com.apple.IconsCache" error:nil];
  [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Caches/MappedImageCache/Persistent" error:nil];
  [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Caches/com.apple.IconsCache" error:nil];
  [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Caches/com.apple.UIStatusBar" error:nil];

  [NSClassFromString(@"Neon") loadPrefs];
  [NSClassFromString(@"Neon") resetMask];
  [NSClassFromString(@"NeonRenderService") resetPrefs];
  [NSClassFromString(@"NeonRenderService") loadPrefs];
  [NSClassFromString(@"NeonRenderService") setupImages];

  [[CPDistributedMessagingCenter centerNamed:@"com.artikus.neonboard"] sendMessageAndReceiveReplyName:@"renderClockIcon" userInfo:nil];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    if ([NSClassFromString(@"NeonRenderService") overlayImage] || [NSClassFromString(@"NeonRenderService") underlay] || [[[NSClassFromString(@"Neon") prefs] objectForKey:@"kMaskRendered"] boolValue]) {
      NSArray *internalApps = [NSArray arrayWithContentsOfFile:@"/Library/PreferenceBundles/neonboardprefs.bundle/InternalApps.plist"];
      NSMutableArray *apps = [[[NSClassFromString(@"LSApplicationWorkspace") defaultWorkspace] allInstalledApplications] mutableCopy];
      for (int i = apps.count - 1; i >= 0; i--) {
        LSApplicationProxy *proxy = apps[i];
        if ([internalApps containsObject:proxy.applicationIdentifier]) [apps removeObjectAtIndex:i];
      }
      __block id progressAlert;
      dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(iOS 8, *)) {
          progressAlert = [UIAlertController alertControllerWithTitle:@"Rendering icons..." message:@"" preferredStyle:UIAlertControllerStyleAlert];
          [[[UIApplication sharedApplication] _rootViewControllers][0] presentViewController:progressAlert animated:YES completion:nil];
        } else {
          progressAlert = [[UIAlertView alloc] initWithTitle:@"Rendering icons..." message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
          [progressAlert setMessage:[NSString stringWithFormat:@"Rendering icon 0 of %lu...", (unsigned long)apps.count]];
          [progressAlert show];
        }
      });
      for (int i = 0; i < apps.count; i++) {
        LSApplicationProxy *proxy = apps[i];
        if ([proxy.applicationIdentifier isEqualToString:@"com.apple.mobiletimer"]) continue;
        [NSClassFromString(@"NeonRenderService") renderIconWithApplicationProxy:proxy];
        dispatch_async(dispatch_get_main_queue(), ^{
          [progressAlert setMessage:[NSString stringWithFormat:@"Rendering icon %d of %lu...", i, (unsigned long)apps.count]];
        });
      }
    }

    // activator frickery because yes
    // TODO not mask glyph (????) (idk really :c)
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Activator.app"]) {
      UIImage *customIcon = [UIImage imageWithContentsOfFile:[NSClassFromString(@"Neon") iconPathForBundleID:@"libactivator"]];
      if (customIcon) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[[NSClassFromString(@"Neon") renderDir] stringByAppendingPathComponent:@"Activator"] withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions: @0777} error:nil];
        CGImageRef mask = [NSClassFromString(@"Neon") getMaskImage].CGImage;
        for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Applications/Activator.app" error:nil]) {
          if (![file hasPrefix:@"Icon"]) continue;
          CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:[@"/Applications/Activator.app" stringByAppendingPathComponent:file]], NULL);
          NSDictionary *imageHeader = (__bridge NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
          CGFloat scale = [UIScreen mainScreen].scale;
          CGSize size = CGSizeMake([imageHeader[@"PixelWidth"] floatValue] / scale, [imageHeader[@"PixelHeight"] floatValue] / scale);
          UIGraphicsBeginImageContextWithOptions(size, NO, scale);
          CGContextClipToMask(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, size.width, size.height), mask);
          [customIcon drawInRect:CGRectMake(0, 0, size.width, size.height)];
          UIImage *final = UIGraphicsGetImageFromCurrentImageContext();
          UIGraphicsEndImageContext();
          [UIImagePNGRepresentation(final) writeToFile:[NSString stringWithFormat:@"%@/Activator/%@", [NSClassFromString(@"Neon") renderDir], file] atomically:YES];
        }
      }
    }

    pid_t pid;
    int status;
    const char *argv[] = {"killall", "-KILL", "lsd", "lsdiconservice", "iconservicesagent", NULL};
    posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)argv, NULL);
    waitpid(pid, &status, WEXITED);

    pid_t pid1;
    int status1;
    const char *argv1[] = {"killall", "-9", "iconservicesagent", "fontservicesd", "SpringBoard", NULL};
    posix_spawn(&pid1, "/usr/bin/killall", NULL, NULL, (char* const*)argv1, NULL);
    waitpid(pid1, &status1, WEXITED);
  });
}
