#import <Foundation/Foundation.h>

@interface BackgroundNSURLSessionFactory : NSObject
- (NSURLSession *)backgroundSessionWithDelegate:(id<NSURLSessionDownloadDelegate>)delegate;
@end