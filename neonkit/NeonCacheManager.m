#include "../Neon.h"
#include "NeonCacheManager.h"

@implementation NeonCacheManager

+ (void)storeCacheImage:(UIImage *)image name:(NSString *)name bundleID:(NSString *)bundleID {
  NSString *path = [NSString stringWithFormat:@"%@/%@/%@.png", @cacheDir, bundleID, name];
  if (![[NSFileManager defaultManager] fileExistsAtPath:path.stringByDeletingLastPathComponent])
		[[NSFileManager defaultManager] createDirectoryAtPath:path.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions: @0777} error:nil];
	[UIImagePNGRepresentation(image) writeToFile:path atomically:YES];
}

+ (UIImage *)getCacheImage:(NSString *)name bundleID:(NSString *)bundleID {
  NSString *path = [NSString stringWithFormat:@"%@/%@/%@.png", @cacheDir, bundleID, name];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		UIImage *image = [UIImage imageWithContentsOfFile:path];
		return [UIImage imageWithCGImage:image.CGImage scale:[UIScreen mainScreen].scale orientation:image.imageOrientation];
	}
	return nil;
}

// what is this? well....
// on ios 7, a *huge* lag was going on in the SpringBoard on performance of various actions (like opening folders, viewing UITableViews, etc.)
// so i logged it. it was requesting the same 3-4 images like 10-15 times. the first thought was creating a cache, but it didn't work....
// and then i understood the images weren't actually present in any themes, and that was the reason they weren't getting cached! so i created this. worked like a charm.
// so, i present you: the unthemed cache.

NSCache *unthemedCache;

+ (BOOL)isImageNameUnthemed:(NSString *)name bundleID:(NSString *)bundleID {
  if (!unthemedCache) unthemedCache = [NSCache new];
  NSArray *arr = [unthemedCache objectForKey:bundleID];
  if (!arr) return NO;
  return [[arr copy] containsObject:name];
}

+ (void)addUnthemedImageName:(NSString *)name bundleID:(NSString *)bundleID {
  if (!unthemedCache) unthemedCache = [NSCache new];
  NSMutableArray *arr = [unthemedCache objectForKey:bundleID] ? : [NSMutableArray new];
  [arr addObject:name];
  [unthemedCache setObject:arr forKey:bundleID];
}

@end
