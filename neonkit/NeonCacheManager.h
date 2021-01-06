@interface NeonCacheManager : NSObject

+ (void)storeCacheImage:(UIImage *)image name:(NSString *)name bundleID:(NSString *)bundleID;
+ (UIImage *)getCacheImage:(NSString *)name bundleID:(NSString *)bundleID;
+ (BOOL)isImageNameUnthemed:(NSString *)name bundleID:(NSString *)bundleID;
+ (void)addUnthemedImageName:(NSString *)name bundleID:(NSString *)bundleID;

@end
