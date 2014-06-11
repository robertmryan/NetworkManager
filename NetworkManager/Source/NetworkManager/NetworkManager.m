//
//  NetworkManager.m
//
//  Created by Robert Ryan on 1/30/14.
//  Copyright (c) 2014 Robert Ryan. All rights reserved.
//
//  This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
//  http://creativecommons.org/licenses/by-sa/4.0/

#import "NetworkManager.h"
@import MobileCoreServices;

static NSMutableDictionary *_backgroundSessions = nil;

@interface NetworkManager ()  <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSMutableDictionary *operations;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOperationQueue *networkQueue;
@property (nonatomic, getter = isBackgroundSession) BOOL backgroundSession;

@end

@implementation NetworkManager

/* Create session manager with default NSURLSession.
 *
 * @return A session manager.
 */
- (instancetype)init
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    return [self initWithSessionConfiguration:configuration];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    NSParameterAssert(configuration);

    self = [super init];
    if (self) {
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        _operations = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (instancetype) backgroundSessionWithIdentifier:(NSString *)identifier
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _backgroundSessions = [[NSMutableDictionary alloc] init];
    });

    NetworkManager *manager = _backgroundSessions[identifier];
    if (!manager) {
        NSURLSessionConfiguration *configuration;

#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
        // temporarily disable deprecated declarations since we don't know what OS version this code will be used in
        // `backgroundSessionConfiguration` was deprecated in OS X 10.10 and iOS 8.0.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

        if ([NSURLSessionConfiguration respondsToSelector:@selector(backgroundSessionConfigurationWithIdentifier:)])
            configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        else
            configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:identifier];

#pragma clang diagnostic pop

#else
        configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:identifier];
#endif

        manager = [[self alloc] initWithSessionConfiguration:configuration];
        manager.backgroundSession = YES;
        _backgroundSessions[identifier] = manager;
    }

    return manager;
}

- (NetworkDataTaskOperation *)dataOperationWithURL:(NSURL *)url
                                   progressHandler:(ProgressHandler)progressHandler
                                 completionHandler:(DidCompleteWithErrorHandler)didCompleteWithErrorHandler;
{
    NSParameterAssert(url);

    return [self dataOperationWithRequest:[NSURLRequest requestWithURL:url]
                          progressHandler:progressHandler
                        completionHandler:didCompleteWithErrorHandler];
}

- (NetworkDataTaskOperation *)dataOperationWithRequest:(NSURLRequest *)request
                                       progressHandler:(ProgressHandler)progressHandler
                                     completionHandler:(DidCompleteWithErrorHandler)didCompleteWithErrorHandler;
{
    NSParameterAssert(request);

    NetworkDataTaskOperation *operation;

    operation = [[NetworkDataTaskOperation alloc] initWithSession:self.session request:request];
    NSAssert(operation, @"%s: instantiation of NetworkDataTaskOperation failed", __FUNCTION__);
    operation.progressHandler = progressHandler;
    operation.didCompleteWithErrorHandler = didCompleteWithErrorHandler;
    operation.completionQueue = self.completionQueue;

    [self.operations setObject:operation forKey:@(operation.task.taskIdentifier)];

    return operation;
}

- (NetworkDownloadTaskOperation *)downloadOperationWithURL:(NSURL *)url
                                       didWriteDataHandler:(DidWriteDataHandler)didWriteDataHandler
                               didFinishDownloadingHandler:(DidFinishDownloadingHandler)didFinishDownloadingHandler
{
    NSParameterAssert(url);

    NetworkDownloadTaskOperation *operation;

    operation = [self downloadOperationWithRequest:[NSURLRequest requestWithURL:url]
                               didWriteDataHandler:didWriteDataHandler
                       didFinishDownloadingHandler:didFinishDownloadingHandler];

    operation.completionQueue = self.completionQueue;

    return operation;
}

- (NetworkDownloadTaskOperation *)downloadOperationWithRequest:(NSURLRequest *)request
                                           didWriteDataHandler:(DidWriteDataHandler)didWriteDataHandler
                                   didFinishDownloadingHandler:(DidFinishDownloadingHandler)didFinishDownloadingHandler
{
    NSParameterAssert(request);

    NetworkDownloadTaskOperation *operation;

    operation = [[NetworkDownloadTaskOperation alloc] initWithSession:self.session request:request];
    NSAssert(operation, @"%s: instantiation of NetworkDownloadTaskOperation failed", __FUNCTION__);
    operation.didFinishDownloadingHandler = didFinishDownloadingHandler;
    operation.didWriteDataHandler = didWriteDataHandler;
    operation.completionQueue = self.completionQueue;

    [self.operations setObject:operation forKey:@(operation.task.taskIdentifier)];

    return operation;
}

- (NetworkUploadTaskOperation *)uploadOperationWithURL:(NSURL *)url
                                                  data:(NSData *)data
                                didSendBodyDataHandler:(DidSendBodyDataHandler)didSendBodyDataHandler
                           didCompleteWithErrorHandler:(DidCompleteWithErrorHandler)didCompleteWithErrorHandler
{
    NSParameterAssert(url);

    NetworkUploadTaskOperation *operation;

    operation = [self uploadOperationWithRequest:[NSURLRequest requestWithURL:url]
                                            data:data
                          didSendBodyDataHandler:didSendBodyDataHandler
                     didCompleteWithErrorHandler:didCompleteWithErrorHandler];
    operation.completionQueue = self.completionQueue;

    return operation;
}

- (NetworkUploadTaskOperation *)uploadOperationWithRequest:(NSURLRequest *)request
                                                      data:(NSData *)data
                                    didSendBodyDataHandler:(DidSendBodyDataHandler)didSendBodyDataHandler
                               didCompleteWithErrorHandler:(DidCompleteWithErrorHandler)didCompleteWithErrorHandler
{
    NSParameterAssert(request);

    NetworkUploadTaskOperation *operation;

    operation = [[NetworkUploadTaskOperation alloc] initWithSession:self.session request:request data:data];
    NSAssert(operation, @"%s: instantiation of NetworkUploadTaskOperation failed", __FUNCTION__);
    operation.didCompleteWithErrorHandler = didCompleteWithErrorHandler;
    operation.didSendBodyDataHandler = didSendBodyDataHandler;
    operation.completionQueue = self.completionQueue;

    [self.operations setObject:operation forKey:@(operation.task.taskIdentifier)];

    return operation;
}

- (NetworkUploadTaskOperation *)uploadOperationWithURL:(NSURL *)url
                                               fileURL:(NSURL *)fileURL
                                didSendBodyDataHandler:(DidSendBodyDataHandler)didSendBodyDataHandler
                           didCompleteWithErrorHandler:(DidCompleteWithErrorHandler)didCompleteWithErrorHandler
{
    NSParameterAssert(url);

    return [self uploadOperationWithRequest:[NSURLRequest requestWithURL:url]
                                    fileURL:fileURL
                     didSendBodyDataHandler:didSendBodyDataHandler
                didCompleteWithErrorHandler:didCompleteWithErrorHandler];
}

- (NetworkUploadTaskOperation *)uploadOperationWithRequest:(NSURLRequest *)request
                                                   fileURL:(NSURL *)url
                                    didSendBodyDataHandler:(DidSendBodyDataHandler)didSendBodyDataHandler
                               didCompleteWithErrorHandler:(DidCompleteWithErrorHandler)didCompleteWithErrorHandler
{
    NSParameterAssert(request);

    NetworkUploadTaskOperation *operation;

    operation = [[NetworkUploadTaskOperation alloc] initWithSession:self.session request:request fromFile:url];
    NSAssert(operation, @"%s: instantiation of NetworkUploadTaskOperation failed", __FUNCTION__);
    operation.didCompleteWithErrorHandler = didCompleteWithErrorHandler;
    operation.didSendBodyDataHandler = didSendBodyDataHandler;
    operation.completionQueue = self.completionQueue;

    [self.operations setObject:operation forKey:@(operation.task.taskIdentifier)];

    return operation;
}

#pragma mark - NSOperationQueue

- (NSOperationQueue *)networkQueue
{
    @synchronized(self) {
        if (!_networkQueue) {
            _networkQueue = [[NSOperationQueue alloc] init];
            _networkQueue.name = @"NetworkManager.queue";
            if (![self isBackgroundSession])
                _networkQueue.maxConcurrentOperationCount = 4;
        }

        return _networkQueue;
    }
}

- (void)addOperation:(NSOperation *)operation
{
    [self.networkQueue addOperation:operation];
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    if (self.didBecomeInvalidWithError) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didBecomeInvalidWithError(self, error);
        });
    }
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    if (self.didReceiveChallenge) {
        self.didReceiveChallenge(self, challenge, completionHandler);
    } else {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            if (self.credential && challenge.previousFailureCount == 0) {
                completionHandler(NSURLSessionAuthChallengeUseCredential, self.credential);
            } else {
                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            }
        });
    }
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session;
{
    BOOL __block shouldCallCompletionHandler;

    // If urlSessionDidFinishEventsHandler available, call it to determine whether
    // the completionHandler should be called.
    //
    // If urlSessionDidFinishEventsHandler not supplied, we'll just assume that
    // the completionHandler should be called.

    if (self.urlSessionDidFinishEventsHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            shouldCallCompletionHandler = self.urlSessionDidFinishEventsHandler(self);
        });
    } else {
        shouldCallCompletionHandler = YES;
    }

    // Call the completion handler (if available)

    if (shouldCallCompletionHandler) {
        if (self.completionHandler) {
            self.completionHandler();
            self.completionHandler = nil;
        }
    }
}

#pragma mark - NSURLSessionTaskDelegate

- (void)removeTaskOperationForTask:(NSURLSessionTask *)task
{
    NetworkTaskOperation *taskOperation = self.operations[@(task.taskIdentifier)];
    NSAssert(taskOperation || (self.session.configuration.identifier != nil), @"%s: task operation %lu not found ", __FUNCTION__, (unsigned long)task.taskIdentifier);

    [self.operations enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (obj == taskOperation) {
            [self.operations removeObjectForKey:key];
            *stop = YES;
        }
    }];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NetworkTaskOperation *operation = self.operations[@(task.taskIdentifier)];
    NSAssert(operation || (self.session.configuration.identifier != nil), @"%s: Did not find taskIdentifier %lu", __FUNCTION__, (unsigned long)task.taskIdentifier);

    if ([operation respondsToSelector:@selector(URLSession:task:didCompleteWithError:)]) {
        [operation URLSession:session task:task didCompleteWithError:error];
    } else {
        if (self.didCompleteWithError) {
            dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
                self.didCompleteWithError(self, task, error);
                self.didCompleteWithError = nil;
            });
        }

        [operation completeOperation];
    }

    [self removeTaskOperationForTask:task];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    NetworkTaskOperation *operation = self.operations[@(task.taskIdentifier)];
    NSAssert(operation || (self.session.configuration.identifier != nil), @"%s: Did not find taskIdentifier %lu", __FUNCTION__, (unsigned long)task.taskIdentifier);

    // if the operation can handle challenge, then give it one shot, otherwise, we'll take over here

    if ([operation respondsToSelector:@selector(URLSession:task:didReceiveChallenge:completionHandler:)] && challenge.previousFailureCount == 0 && [operation canRespondToChallenge]) {
        [operation URLSession:session task:task didReceiveChallenge:challenge completionHandler:completionHandler];
    } else {
        if (self.didReceiveChallenge) {
            dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
                self.didReceiveChallenge(self, challenge, completionHandler);
            });
        } else {
            if (self.credential && challenge.previousFailureCount == 0) {
                completionHandler(NSURLSessionAuthChallengeUseCredential, self.credential);
            } else {
                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            }
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    NetworkTaskOperation *operation = self.operations[@(task.taskIdentifier)];
    NSAssert(operation || (self.session.configuration.identifier != nil), @"%s: Did not find taskIdentifier %lu", __FUNCTION__, (unsigned long)task.taskIdentifier);

    if ([operation respondsToSelector:@selector(URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)])
        [operation URLSession:session task:task didSendBodyData:bytesSent totalBytesSent:totalBytesSent totalBytesExpectedToSend:totalBytesExpectedToSend];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler
{
    NetworkTaskOperation *operation = self.operations[@(task.taskIdentifier)];
    NSAssert(operation || (self.session.configuration.identifier != nil), @"%s: Did not find taskIdentifier %lu", __FUNCTION__, (unsigned long)task.taskIdentifier);

    if ([operation respondsToSelector:@selector(URLSession:task:needNewBodyStream:)])
        [operation URLSession:session task:task needNewBodyStream:completionHandler];
    else
        completionHandler(nil);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    NetworkTaskOperation *operation = self.operations[@(task.taskIdentifier)];
    NSAssert(operation || (self.session.configuration.identifier != nil), @"%s: Did not find taskIdentifier %lu", __FUNCTION__, (unsigned long)task.taskIdentifier);

    if ([operation respondsToSelector:@selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:)])
        [operation URLSession:session task:task willPerformHTTPRedirection:response newRequest:request completionHandler:completionHandler];
    else
        completionHandler(request);
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    NetworkDataTaskOperation *operation = self.operations[@(dataTask.taskIdentifier)];
    NSAssert(operation, @"%s: Did not find taskIdentifier %lu", __FUNCTION__, (unsigned long)dataTask.taskIdentifier);

    if ([operation respondsToSelector:@selector(URLSession:dataTask:didReceiveResponse:completionHandler:)])
        [operation URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
    else
        completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    NetworkDataTaskOperation *operation = self.operations[@(dataTask.taskIdentifier)];
    NSAssert(operation, @"%s: Did not find taskIdentifier %lu", __FUNCTION__, (unsigned long)dataTask.taskIdentifier);

    if ([operation respondsToSelector:@selector(URLSession:dataTask:didReceiveData:)])
        [operation URLSession:session dataTask:dataTask didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler
{
    NetworkDataTaskOperation *operation = self.operations[@(dataTask.taskIdentifier)];
    NSAssert(operation, @"%s: Did not find taskIdentifier %lu", __FUNCTION__, (unsigned long)dataTask.taskIdentifier);

    if ([operation respondsToSelector:@selector(URLSession:dataTask:willCacheResponse:completionHandler:)])
        [operation URLSession:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
    else
        completionHandler(proposedResponse);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
    NetworkDataTaskOperation *operation = self.operations[@(dataTask.taskIdentifier)];
    NSAssert(operation, @"%s: Did not find taskIdentifier %lu", __FUNCTION__, (unsigned long)dataTask.taskIdentifier);

    if ([operation respondsToSelector:@selector(URLSession:dataTask:didBecomeDownloadTask:)])
        [operation URLSession:session dataTask:dataTask didBecomeDownloadTask:downloadTask];
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NetworkDownloadTaskOperation *operation = self.operations[@(downloadTask.taskIdentifier)];
    NSAssert(operation || (self.session.configuration.identifier != nil), @"%s: Did not find taskIdentifier %lu", __FUNCTION__, (unsigned long)downloadTask.taskIdentifier);

    if ([operation respondsToSelector:@selector(URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)])
        [operation URLSession:session downloadTask:downloadTask didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    NetworkDownloadTaskOperation *operation = self.operations[@(downloadTask.taskIdentifier)];
    NSAssert(operation || (self.session.configuration.identifier != nil), @"%s: Did not find taskIdentifier %lu", __FUNCTION__, (unsigned long)downloadTask.taskIdentifier);

    if ([operation respondsToSelector:@selector(URLSession:downloadTask:didResumeAtOffset:expectedTotalBytes:)])
        [operation URLSession:session downloadTask:downloadTask didResumeAtOffset:fileOffset expectedTotalBytes:expectedTotalBytes];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NetworkDownloadTaskOperation *operation = self.operations[@(downloadTask.taskIdentifier)];
    NSAssert(operation || (self.session.configuration.identifier != nil), @"%s: Did not find taskIdentifier %lu", __FUNCTION__, (unsigned long)downloadTask.taskIdentifier);

    if ([operation respondsToSelector:@selector(URLSession:downloadTask:didFinishDownloadingToURL:)] && operation.didFinishDownloadingHandler) {
        [operation URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:location];
    } else if (self.didFinishDownloadingToURL) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didFinishDownloadingToURL(self, downloadTask, location);
            self.didFinishDownloadingToURL = nil;
        });
    }
}


#pragma mark - Utility Methods

- (NSString *)mimeTypeForPath:(NSString *)path
{
    // get a mime type for an extension using MobileCoreServices.framework

    CFStringRef extension = (__bridge CFStringRef)[path pathExtension];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, extension, NULL);
    assert(UTI != NULL);

    NSString *mimetype = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType));
    assert(mimetype != NULL);

    CFRelease(UTI);

    return mimetype;
}

- (NSString *)generateBoundaryString
{
    // generate boundary string
    //
    // adapted from http://developer.apple.com/library/ios/#samplecode/SimpleURLConnections

    CFUUIDRef  uuid;
    NSString  *uuidStr;

    uuid = CFUUIDCreate(NULL);
    assert(uuid != NULL);

    uuidStr = CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
    assert(uuidStr != NULL);

    CFRelease(uuid);

    return [NSString stringWithFormat:@"Boundary-%@", uuidStr];
}

- (NSData *)createBodyWithBoundary:(NSString *)boundary
                        parameters:(NSDictionary *)parameters
                             paths:(NSArray *)paths
                         fieldName:(NSString *)fieldName
{
    NSMutableData *httpBody = [NSMutableData data];

    // add params (all params are strings)

    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *parameterKey, NSString *parameterValue, BOOL *stop) {
        [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", parameterKey] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"%@\r\n", parameterValue] dataUsingEncoding:NSUTF8StringEncoding]];
    }];

    // add image data

    for (NSString *path in paths) {
        NSString *filename  = [path lastPathComponent];
        NSData   *data      = [NSData dataWithContentsOfFile:path];
        NSString *mimetype  = [self mimeTypeForPath:path];

        [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", fieldName, filename] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimetype] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:data];
        [httpBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }

    [httpBody appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    return httpBody;
}

- (NetworkUploadTaskOperation *)postUploadToURL:(NSURL *)url
                                     parameters:(NSDictionary *)parameters
                                          paths:(NSArray *)paths
                                      fieldName:(NSString *)fieldName
                                     completion:(void (^)(id responseObject, NSError *error))completion
{
    NSString *boundary = [self generateBoundaryString];

    // configure the request

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:NO];
    [request setTimeoutInterval:30];
    [request setHTTPMethod:@"POST"];

    // set content type

    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];

    // create body

    NSData *httpBody = [self createBodyWithBoundary:boundary parameters:parameters paths:paths fieldName:fieldName];

    // setting the body of the post to the reqeust

    NetworkUploadTaskOperation *operation = [self uploadOperationWithRequest:request data:httpBody didSendBodyDataHandler:nil didCompleteWithErrorHandler:^(NetworkTaskOperation *operation, NSData *data, NSError *error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *) operation.task.response;
        BOOL isJSON = NO;

        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            for (NSString *headerKey in response.allHeaderFields) {
                if ([[headerKey lowercaseString] isEqualToString:@"content-type"]) {
                    if ([[response.allHeaderFields[headerKey] lowercaseString] isEqualToString:@"application/json"])
                        isJSON = YES;
                }
            }
        }

        if (completion) {
            if (isJSON) {
                NSError *parseError = nil;
                id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                completion(object, parseError);
            } else {
                completion(data, error);
            }
        } else if (error) {
            NSLog(@"%s: %@", __PRETTY_FUNCTION__, error);
        }
    }];
    
    [self addOperation:operation];
    
    return operation;
}

@end
