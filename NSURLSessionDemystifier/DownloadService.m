#import "DownloadService.h"

#import "BackgroundNSURLSessionFactory.h"
#import "RequestHelper.h"

@interface DownloadService ()
@property (nonatomic, readonly) BackgroundNSURLSessionFactory *sessionFactory;
@property (nonatomic, readonly) RequestHelper *requestHelper;
@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSMutableSet *urnsCurrentlyDownloading;
@end

@implementation DownloadService

#pragma mark - Constants

static DownloadService *sharedInstance;

#pragma mark - Initialization

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _sessionFactory = [[BackgroundNSURLSessionFactory alloc] init];
        _session = [_sessionFactory backgroundSessionWithDelegate:self];
        _requestHelper = [[RequestHelper alloc] init];
        self.urnsCurrentlyDownloading = [NSMutableSet set];
        [self getCurrentTasksWithDetail:YES];
        [self resumeCurrentTasks];
    }
    return self;
}

#pragma mark - Public

- (void)download:(NSString *)urnString
{
    NSURLRequest *request = [self.requestHelper downloadRequestForUrnString:urnString];
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithRequest:request];
    [task resume];
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    NSLog(@"didBecomeInvalidWithError: %@", error);
    [self getCurrentTasksWithDetail:NO];
    self.session = [self.sessionFactory backgroundSessionWithDelegate:self];
    [self getCurrentTasksWithDetail:NO];
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    NSLog(@"URLSessionDidFinishEventsForBackgroundURLSession: %@, performing completion handler...", session);
    [self getCurrentTasksWithDetail:YES];
    if (self.completionHandler) {
        self.completionHandler();
        self.completionHandler = nil;
    } else {
        NSLog(@"completionHandler missing!");
    }
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSString *urnString = [self.requestHelper urnStringFromSessionTask:task];
    [self removeUrnFromDelegateTracking:urnString];
    NSLog(@"didCompleteWithError: %@, %@ task: %@ URLSession: %@", urnString, error, task, session);
    [self getCurrentTasksWithDetail:NO];
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)       URLSession:(NSURLSession *)session
             downloadTask:(NSURLSessionDownloadTask *)downloadTask
             didWriteData:(int64_t)bytesWritten
        totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSString *urnString = [self.requestHelper urnStringFromSessionTask:downloadTask];
    if ([self shouldInformDelegateAboutBeginningDownloadForUrn:urnString]) {
        [self informDelegateAboutBeginningDownloadForUrn:urnString];
        NSLog(@"%@ didWriteData: %@ downloadTask: %@ URLSession: %@", urnString, @(bytesWritten), downloadTask, session);
        // inform delegate in real app
    }
}

- (void)       URLSession:(NSURLSession *)session
             downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    NSString *urnString = [self.requestHelper urnStringFromSessionTask:downloadTask];
    NSLog(@"didFinishDownloadingToURL: %@, downloadTask: %@ location: %@ URLSession: %@",
            urnString, downloadTask, location, session);
}

#pragma mark - Private

- (void)getCurrentTasksWithDetail:(BOOL)includeDetail
{
    NSLog(@"reading current tasks...");
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        NSLog(@"got %@ active downloadTasks", @(downloadTasks.count));
        if (includeDetail) {
            for (NSURLSessionDownloadTask *downloadTask in downloadTasks) {
                NSLog(@"%@ - %@", [self.requestHelper urnStringFromSessionTask:downloadTask], downloadTask);
            }
        }
    }];
}

- (void)resumeCurrentTasks
{
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        NSLog(@"resuming %@ active downloadTasks (just to be sure)", @(downloadTasks.count));
        for (NSURLSessionDownloadTask *downloadTask in downloadTasks) {
            [downloadTask resume];
        }
    }];
}

- (void)informDelegateAboutBeginningDownloadForUrn:(NSString *)urnString
{
    [self.urnsCurrentlyDownloading addObject:urnString];
}

- (void)removeUrnFromDelegateTracking:(NSString *)urnString
{
    [self.urnsCurrentlyDownloading removeObject:urnString];
}

- (BOOL)shouldInformDelegateAboutBeginningDownloadForUrn:(NSString *)urnString
{
    return ![self.urnsCurrentlyDownloading containsObject:urnString];
}

@end
