//
//  NetworkManager.m
//
//  Created by Robert Ryan on 1/30/14.
//  Copyright (c) 2014 Robert Ryan. All rights reserved.
//
//  This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
//  http://creativecommons.org/licenses/by-sa/4.0/

#import "NetworkManager.h"

NSString * const kNetworkManagerVersion = @"0.1";

static NSMutableDictionary *_backgroundSessions;

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
                                 completionHandler:(DidCompleteWithDataErrorHandler)didCompleteWithDataErrorHandler;
{
    NSParameterAssert(url);

    return [self dataOperationWithRequest:[NSURLRequest requestWithURL:url]
                          progressHandler:progressHandler
                        completionHandler:didCompleteWithDataErrorHandler];
}

- (NetworkDataTaskOperation *)dataOperationWithRequest:(NSURLRequest *)request
                                       progressHandler:(ProgressHandler)progressHandler
                                     completionHandler:(DidCompleteWithDataErrorHandler)didCompleteWithDataErrorHandler;
{
    NSParameterAssert(request);

    NetworkDataTaskOperation *operation;

    operation = [[NetworkDataTaskOperation alloc] initWithSession:self.session request:request];
    NSAssert(operation, @"%s: instantiation of NetworkDataTaskOperation failed", __FUNCTION__);
    operation.progressHandler = progressHandler;
    operation.didCompleteWithDataErrorHandler = didCompleteWithDataErrorHandler;
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

- (NetworkDownloadTaskOperation *)downloadOperationWithResumeData:(NSData *)resumeData
                                              didWriteDataHandler:(DidWriteDataHandler)didWriteDataHandler
                                      didFinishDownloadingHandler:(DidFinishDownloadingHandler)didFinishDownloadingHandler
{
    NSParameterAssert(resumeData);

    NetworkDownloadTaskOperation *operation;

    operation = [[NetworkDownloadTaskOperation alloc] initWithSession:self.session resumeData:resumeData];
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
                           didCompleteWithDataErrorHandler:(DidCompleteWithDataErrorHandler)didCompleteWithDataErrorHandler
{
    NSParameterAssert(url);

    NetworkUploadTaskOperation *operation;

    operation = [self uploadOperationWithRequest:[NSURLRequest requestWithURL:url]
                                            data:data
                          didSendBodyDataHandler:didSendBodyDataHandler
                 didCompleteWithDataErrorHandler:didCompleteWithDataErrorHandler];
    operation.completionQueue = self.completionQueue;

    return operation;
}

- (NetworkUploadTaskOperation *)uploadOperationWithRequest:(NSURLRequest *)request
                                                      data:(NSData *)data
                                    didSendBodyDataHandler:(DidSendBodyDataHandler)didSendBodyDataHandler
                               didCompleteWithDataErrorHandler:(DidCompleteWithDataErrorHandler)didCompleteWithDataErrorHandler
{
    NSParameterAssert(request);

    NetworkUploadTaskOperation *operation;

    operation = [[NetworkUploadTaskOperation alloc] initWithSession:self.session request:request data:data];
    NSAssert(operation, @"%s: instantiation of NetworkUploadTaskOperation failed", __FUNCTION__);
    operation.didCompleteWithDataErrorHandler = didCompleteWithDataErrorHandler;
    operation.didSendBodyDataHandler = didSendBodyDataHandler;
    operation.completionQueue = self.completionQueue;

    [self.operations setObject:operation forKey:@(operation.task.taskIdentifier)];

    return operation;
}

- (NetworkUploadTaskOperation *)uploadOperationWithURL:(NSURL *)url
                                               fileURL:(NSURL *)fileURL
                                didSendBodyDataHandler:(DidSendBodyDataHandler)didSendBodyDataHandler
                           didCompleteWithDataErrorHandler:(DidCompleteWithDataErrorHandler)didCompleteWithDataErrorHandler
{
    NSParameterAssert(url);

    return [self uploadOperationWithRequest:[NSURLRequest requestWithURL:url]
                                    fileURL:fileURL
                     didSendBodyDataHandler:didSendBodyDataHandler
            didCompleteWithDataErrorHandler:didCompleteWithDataErrorHandler];
}

- (NetworkUploadTaskOperation *)uploadOperationWithRequest:(NSURLRequest *)request
                                                   fileURL:(NSURL *)url
                                    didSendBodyDataHandler:(DidSendBodyDataHandler)didSendBodyDataHandler
                           didCompleteWithDataErrorHandler:(DidCompleteWithDataErrorHandler)didCompleteWithDataErrorHandler
{
    NSParameterAssert(request);

    NetworkUploadTaskOperation *operation;

    operation = [[NetworkUploadTaskOperation alloc] initWithSession:self.session request:request fromFile:url];
    NSAssert(operation, @"%s: instantiation of NetworkUploadTaskOperation failed", __FUNCTION__);
    operation.didCompleteWithDataErrorHandler = didCompleteWithDataErrorHandler;
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
            _networkQueue.name = [NSString stringWithFormat:@"%@.NetworkManager.%p", [[NSBundle mainBundle] bundleIdentifier], self];
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
        if (self.credential && challenge.previousFailureCount == 0) {
            completionHandler(NSURLSessionAuthChallengeUseCredential, self.credential);
        } else {
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        }
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

    if (!taskOperation)
        return;
    
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

    if ([operation respondsToSelector:@selector(URLSession:task:didCompleteWithError:)] && operation.didCompleteWithDataErrorHandler) {
        [operation URLSession:session task:task didCompleteWithError:error];
    } else {
        if (self.didCompleteWithError) {
            dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
                self.didCompleteWithError(self, task, error);
            });
        }

        [operation completeOperation];
    }

    [self removeTaskOperationForTask:task];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    NetworkTaskOperation *operation = self.operations[@(task.taskIdentifier)];

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

    if ([operation respondsToSelector:@selector(URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)])
        [operation URLSession:session task:task didSendBodyData:bytesSent totalBytesSent:totalBytesSent totalBytesExpectedToSend:totalBytesExpectedToSend];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler
{
    NetworkTaskOperation *operation = self.operations[@(task.taskIdentifier)];

    if ([operation respondsToSelector:@selector(URLSession:task:needNewBodyStream:)])
        [operation URLSession:session task:task needNewBodyStream:completionHandler];
    else
        completionHandler(nil);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    NetworkTaskOperation *operation = self.operations[@(task.taskIdentifier)];

    if ([operation respondsToSelector:@selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:)])
        [operation URLSession:session task:task willPerformHTTPRedirection:response newRequest:request completionHandler:completionHandler];
    else
        completionHandler(request);
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    NetworkDataTaskOperation *operation = self.operations[@(dataTask.taskIdentifier)];

    if ([operation respondsToSelector:@selector(URLSession:dataTask:didReceiveResponse:completionHandler:)])
        [operation URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
    else
        completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    NetworkDataTaskOperation *operation = self.operations[@(dataTask.taskIdentifier)];

    if ([operation respondsToSelector:@selector(URLSession:dataTask:didReceiveData:)])
        [operation URLSession:session dataTask:dataTask didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler
{
    NetworkDataTaskOperation *operation = self.operations[@(dataTask.taskIdentifier)];

    if ([operation respondsToSelector:@selector(URLSession:dataTask:willCacheResponse:completionHandler:)])
        [operation URLSession:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
    else
        completionHandler(proposedResponse);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
    NetworkDataTaskOperation *operation = self.operations[@(dataTask.taskIdentifier)];

    if ([operation respondsToSelector:@selector(URLSession:dataTask:didBecomeDownloadTask:)])
        [operation URLSession:session dataTask:dataTask didBecomeDownloadTask:downloadTask];
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NetworkDownloadTaskOperation *operation = self.operations[@(downloadTask.taskIdentifier)];

    if ([operation respondsToSelector:@selector(URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)])
        [operation URLSession:session downloadTask:downloadTask didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    NetworkDownloadTaskOperation *operation = self.operations[@(downloadTask.taskIdentifier)];

    if ([operation respondsToSelector:@selector(URLSession:downloadTask:didResumeAtOffset:expectedTotalBytes:)])
        [operation URLSession:session downloadTask:downloadTask didResumeAtOffset:fileOffset expectedTotalBytes:expectedTotalBytes];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NetworkDownloadTaskOperation *operation = self.operations[@(downloadTask.taskIdentifier)];

    if ([operation respondsToSelector:@selector(URLSession:downloadTask:didFinishDownloadingToURL:)] && operation.didFinishDownloadingHandler) {
        [operation URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:location];
    } else if (self.didFinishDownloadingToURL) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didFinishDownloadingToURL(self, downloadTask, location);
        });
    }
}


@end
