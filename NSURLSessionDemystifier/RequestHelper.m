#import "RequestHelper.h"

@implementation RequestHelper

#pragma mark - Contants

NSString *const kRequestCustomPropertyUrn = @"com.soundcloud.urn";
NSString *const kAuthorizationHeader = @"Authorization";

#pragma mark - Public

- (NSURLRequest *)downloadRequestForUrnString:(NSString *)urnString
{
    NSURL *downloadUrl = [self downloadUrlForUrnString:urnString];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:downloadUrl];
    [NSURLProtocol setProperty:urnString forKey:kRequestCustomPropertyUrn inRequest:urlRequest];
    [urlRequest setValue:@"OAuth 1-117752-141349303-98f413e94200f" forHTTPHeaderField:kAuthorizationHeader];
    return [urlRequest copy];
}

- (NSString *)urnStringFromSessionTask:(NSURLSessionTask *)task
{
    NSString *urnString = [NSURLProtocol propertyForKey:kRequestCustomPropertyUrn inRequest:task.originalRequest];
    if (urnString == nil) {
        urnString = [self hackUrnFromTheRequestUrl:task];
    }
    
    return urnString;
}

#pragma mark - Private

- (NSURL *)downloadUrlForUrnString:(NSString *)urnString
{
    NSString *downloadUrlString = [NSString stringWithFormat:
                                   @"https://api-mobile-dev.soundcloud.com/tracks/%@/download?key_id=0&client_id=e825c3bb4ea6172167da269f8d2923c5", urnString];
    return [NSURL URLWithString:downloadUrlString];
}

- (NSString *)hackUrnFromTheRequestUrl:(NSURLSessionTask *)task
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@".*(soundcloud:tracks:\\d+).*"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    
    NSString *urlString = [task.originalRequest.URL absoluteString];
    NSTextCheckingResult *matchResult = [regex firstMatchInString:urlString options:0 range:NSMakeRange(0, urlString.length)];
    NSAssert(matchResult && [matchResult rangeAtIndex:1].location != NSNotFound,
             @"URN is not appended to the request neither contained in the URL: %@ (task: %@)", task.originalRequest, task);
    
    NSString *urnString = [urlString substringWithRange:[matchResult rangeAtIndex:1]];
    NSLog(@"Could not extract URN from task's request %@; extract-hacking from URL", task.originalRequest);
    
    return urnString;
}

@end
