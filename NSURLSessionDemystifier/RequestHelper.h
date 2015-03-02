#import <Foundation/Foundation.h>

@interface RequestHelper : NSObject
- (NSURLRequest *)downloadRequestForUrnString:(NSString *)urnString;
- (NSString *)urnStringFromSessionTask:(NSURLSessionTask *)task;
@end
