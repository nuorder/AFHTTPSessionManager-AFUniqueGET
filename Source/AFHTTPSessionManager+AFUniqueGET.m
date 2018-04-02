#import "AFHTTPSessionManager+AFUniqueGET.h"

@implementation AFHTTPSessionManager (AFUniqueGET)

- (void)uniqueGET:(NSString *)URLString
       parameters:(id)parameters
      cachePolicy:(NSURLRequestCachePolicy)cachePolicy
             task:(void (^)(NSURLSessionDataTask *task, BOOL existing))task
          success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
          failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSParameterAssert(URLString);

    NSString *path = [[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString];

    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET"
                                                                   URLString:path
                                                                  parameters:parameters
                                                                       error:&error];
    request.cachePolicy = cachePolicy;
    if (error) {
        if (failure) {
            failure(nil, error);
        }
    } else {
        [self request:request exists:^(NSURLSessionDataTask *existingTask) {
            if (existingTask) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (task) {
                        task(existingTask, YES);
                    }
                });
            } else {
                @try {
                    __block NSURLSessionDataTask *dataTask = [self dataTaskWithRequest:request
                                                                        uploadProgress:nil
                                                                      downloadProgress:nil
                                                                     completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                             if (error && failure) {
                                                                                 failure(dataTask, error);
                                                                             } else if (success) {
                                                                                 success(dataTask, responseObject);
                                                                             }
                                                                         });
                                                                     }];
                    [dataTask resume];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (task) {
                            task(dataTask, NO);
                        }
                    });
                } @catch (NSException *exception) {
                    
                }
            }
        }];
    }
}

- (void)request:(NSMutableURLRequest *)request
         exists:(void (^)(NSURLSessionDataTask *existingTask))exists
{
    __block NSURLSessionDataTask *existingTask;

    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks,
                                                  NSArray * __unused uploadTasks,
                                                  NSArray * __unused downloadTasks) {

        for (NSURLSessionDataTask *dataTask in dataTasks) {
            if ([[dataTask.originalRequest.URL absoluteString] isEqualToString:[request.URL absoluteString]]) {
                existingTask = dataTask;
                break;
            }
        }

        if (exists) {
            exists(existingTask);
        }
    }];
}

@end
