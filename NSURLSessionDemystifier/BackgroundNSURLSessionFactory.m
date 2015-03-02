#import "BackgroundNSURLSessionFactory.h"

@implementation BackgroundNSURLSessionFactory

#pragma mark - Constants

static NSString *const kOfflineSyncDownloadSessionIdentifier = @"com.soundcloud.OfflineSync.BackgroundUrlSession";

#pragma mark - Public

- (NSURLSession *)backgroundSessionWithDelegate:(id<NSURLSessionDownloadDelegate>)delegate
{
    return [NSURLSession sessionWithConfiguration:[self backgroundSessionConfiguration]
                                         delegate:delegate
                                    delegateQueue:[self delegateQueue]];
}

#pragma mark - Private

- (NSURLSessionConfiguration *)backgroundSessionConfiguration
{
    NSURLSessionConfiguration *configuration;
    if ([NSURLSessionConfiguration respondsToSelector:@selector(backgroundSessionConfigurationWithIdentifier:)]) {
        configuration = [NSURLSessionConfiguration
                         backgroundSessionConfigurationWithIdentifier:kOfflineSyncDownloadSessionIdentifier];
    } else {
        configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:kOfflineSyncDownloadSessionIdentifier];
    }
    configuration.allowsCellularAccess = NO;
    configuration.URLCache = nil;
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
    configuration.networkServiceType = NSURLNetworkServiceTypeBackground;
    configuration.HTTPMaximumConnectionsPerHost = 1;
    return configuration;
}

- (NSOperationQueue *)delegateQueue
{
    NSOperationQueue *delegateQueue = [NSOperationQueue mainQueue];
    return delegateQueue;
}

@end
