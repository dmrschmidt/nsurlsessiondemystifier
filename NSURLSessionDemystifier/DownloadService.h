#import <Foundation/Foundation.h>

@interface DownloadService : NSObject <NSURLSessionDownloadDelegate>
@property (nonatomic, copy) void (^completionHandler)();

+ (instancetype)sharedInstance;
- (void)download:(NSString *)urnString;
@end
