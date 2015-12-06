//
//  NetworkDownloadTaskOperation.m
//
//  Created by Robert Ryan on 3/5/14.
//  Copyright (c) 2014 Robert Ryan. All rights reserved.
//
//  This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
//  http://creativecommons.org/licenses/by-sa/4.0/

#import "NetworkDownloadTaskOperation.h"

@implementation NetworkDownloadTaskOperation

#pragma mark - NSURLSessionDownloadDelegate

- (instancetype)initWithSession:(NSURLSession *)session
                        request:(NSURLRequest *)request {
    self = [super init];
    if (self) {
        self.task = [session downloadTaskWithRequest:request];
    }
    return self;
}

- (instancetype)initWithSession:(NSURLSession *)session
                     resumeData:(NSData *)resumeData {
    NSParameterAssert(resumeData);

    self = [super init];
    if (self) {
        self.task = [session downloadTaskWithResumeData:resumeData];
    }
    return self;
}

- (void)cancelByProducingResumeData:(void (^)(NSData *resumeData))completionHandler {
    if (self.task.state == NSURLSessionTaskStateRunning) {
        [(NSURLSessionDownloadTask *)self.task cancelByProducingResumeData:^(NSData *resumeData) {
            completionHandler(resumeData);
        }];
    } else {
        completionHandler(nil);
    }
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (self.didFinishDownloadingHandler) {
        if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSInteger statusCode = [(NSHTTPURLResponse *)task.response statusCode];
            if (statusCode != 200 && error == nil)
                error = [NSError errorWithDomain:NSStringFromClass([self class]) code:statusCode userInfo:@{@"statusCode": @(statusCode), @"response": task.response}];
        }

        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didFinishDownloadingHandler(self, nil, error);
            self.didFinishDownloadingHandler = nil;
            self.didResumeHandler = nil;
            self.didWriteDataHandler = nil;
        });
    } else {
        self.didResumeHandler = nil;
        self.didWriteDataHandler = nil;
    }

    [super URLSession:session task:task didCompleteWithError:error];
}

#pragma mark - NSURLSessionDownloadTaskDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    if (self.didFinishDownloadingHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didFinishDownloadingHandler(self, location, nil);
            self.didFinishDownloadingHandler = nil;
            self.didResumeHandler = nil;
            self.didWriteDataHandler = nil;
        });
    } else {
        self.didResumeHandler = nil;
        self.didWriteDataHandler = nil;
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    if (self.didResumeHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didResumeHandler(self, fileOffset, expectedTotalBytes);
        });
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    if (self.didWriteDataHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didWriteDataHandler(self, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        });
    }
}

@end
