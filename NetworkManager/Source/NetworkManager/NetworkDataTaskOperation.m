//
//  RRNetworkTaskOperation.m
//
//  Created by Robert Ryan on 1/30/14.
//  Copyright (c) 2014 Robert Ryan. All rights reserved.
//
//  This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
//  http://creativecommons.org/licenses/by-sa/4.0/

#import "NetworkDataTaskOperation.h"

@interface NetworkDataTaskOperation ()

@property (nonatomic) long long totalBytesExpected;
@property (nonatomic) long long bytesReceived;

@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSError *error;

@end

@implementation NetworkDataTaskOperation

- (instancetype)initWithSession:(NSURLSession *)session
                        request:(NSURLRequest *)request
{
    self = [super init];
    if (self) {
        self.task = [session dataTaskWithRequest:request];
    }
    return self;
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (self.didCompleteWithErrorHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didCompleteWithErrorHandler(self, self.responseData, self.error ?: error);
            self.didCompleteWithErrorHandler = nil;
            self.responseData = nil;
        });
    }

    [self completeOperation];
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    if (self.didReceiveResponseHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didReceiveResponseHandler(self, response, completionHandler);
        });
    } else {
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            self.totalBytesExpected = [(NSHTTPURLResponse *)response expectedContentLength];
            self.bytesReceived = 0ll;

            if (statusCode == 200) {
                if (!self.didReceiveDataHandler) {
                    self.responseData = [NSMutableData data];
                }
                completionHandler(NSURLSessionResponseAllow);
            } else {
                completionHandler(NSURLSessionResponseCancel);
                if (self.didCompleteWithErrorHandler) {
                    self.error = [NSError errorWithDomain:NSStringFromClass([self class]) code:statusCode userInfo:@{@"statusCode": @(statusCode), @"response": dataTask.response}];
                }
            }

            return;
        }
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    self.bytesReceived += [data length];

    if (self.didReceiveDataHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didReceiveDataHandler(self, data, self.totalBytesExpected, self.bytesReceived);
        });
    } else {
        [self.responseData appendData:data];
    }

    if (self.progressHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.progressHandler(self, self.totalBytesExpected, self.bytesReceived);
        });
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler
{
    if (self.willCacheResponseHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.willCacheResponseHandler(self, proposedResponse, completionHandler);
        });
    } else {
        completionHandler(proposedResponse);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
    if (self.didBecomeDownloadTaskHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didBecomeDownloadTaskHandler(self, downloadTask);
        });
    }
}

@end
