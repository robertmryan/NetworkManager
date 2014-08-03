//
//  NetworkTaskOperation.m
//
//  Created by Robert Ryan on 3/5/14.
//  Copyright (c) 2014 Robert Ryan. All rights reserved.
//
//  This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
//  http://creativecommons.org/licenses/by-sa/4.0/

#import "NetworkTaskOperation.h"
#import "NetworkDataTaskOperation.h"
//@import MobileCoreServices;

@interface NetworkTaskOperation ()

@property (nonatomic, readwrite, getter = isFinished)  BOOL finished;
@property (nonatomic, readwrite, getter = isExecuting) BOOL executing;

@end

@implementation NetworkTaskOperation

@synthesize executing = _executing;
@synthesize finished  = _finished;

- (instancetype)initWithSession:(NSURLSession *)session
                        request:(NSURLRequest *)request
{
    NSAssert(FALSE, @"%s should not be called for NetworkTaskOperation, but rather NetworkDataTaskOperation, NetworkDownloadTaskOperation, or NetworkUploadTaskOperation", __FUNCTION__);

    return nil;
}

- (BOOL)canRespondToChallenge
{
    return self.credential || self.didReceiveChallengeHandler;
}

- (void)start
{
    if ([self isCancelled]) {
        self.finished = YES;
        return;
    }

    self.executing = YES;

    [self.task resume];
}

- (void)cancel
{
    [self.task cancel];
    [super cancel];
}

- (void)completeOperation
{
    self.executing = NO;
    self.finished = YES;
}

#pragma mark - NSOperation methods

- (BOOL)isConcurrent
{
    return YES;
}

- (void)setExecuting:(BOOL)executing
{
    if (executing != _executing) {
        [self willChangeValueForKey:@"isExecuting"];
        _executing = executing;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (void)setFinished:(BOOL)finished
{
    if (finished != _finished) {
        [self willChangeValueForKey:@"isFinished"];
        _finished = finished;
        [self didChangeValueForKey:@"isFinished"];
    }
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (self.didCompleteWithDataErrorHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didCompleteWithDataErrorHandler(self, nil, error);
            self.didCompleteWithDataErrorHandler = nil;
        });
    }

    [self completeOperation];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    if (self.didReceiveChallengeHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didReceiveChallengeHandler(self, challenge, completionHandler);
        });
    } else {
        if (challenge.previousFailureCount == 0 && self.credential)
            completionHandler(NSURLSessionAuthChallengeUseCredential, self.credential);
        else
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    if (self.didSendBodyDataHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didSendBodyDataHandler(self, bytesSent, totalBytesSent, totalBytesExpectedToSend);
        });
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler
{
    if (self.needNewBodyStreamHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.needNewBodyStreamHandler(self, completionHandler);
        });
    } else {
        completionHandler(nil);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    if (self.willPerformHTTPRedirectionHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.willPerformHTTPRedirectionHandler(self, response, request, completionHandler);
        });
    } else {
        completionHandler(request);
    }
}

@end
