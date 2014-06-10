//
//  NetworkTaskOperation.h
//
//  Created by Robert Ryan on 3/5/14.
//  Copyright (c) 2014 Robert Ryan. All rights reserved.
//
//  This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
//  http://creativecommons.org/licenses/by-sa/4.0/

#import <Foundation/Foundation.h>

@class NetworkTaskOperation;

typedef void(^DidCompleteWithErrorHandler)(NetworkTaskOperation *operation,
                                           NSData *data,
                                           NSError *error);

typedef void(^DidReceiveChallengeHandler)(NetworkTaskOperation *operation,
                                          NSURLAuthenticationChallenge *challenge,
                                          void(^completionHandler)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential)
                                          );

typedef void(^DidSendBodyDataHandler)(NetworkTaskOperation *operation,
                                      int64_t bytesSent,
                                      int64_t totalBytesSent,
                                      int64_t totalBytesExpectedToSend);

typedef void(^NeedNewBodyStreamHandler)(NetworkTaskOperation *operation,
                                        void(^completionHandler)(NSInputStream *bodyStream));

typedef void(^WillPerformHTTPRedirectionHandler)(NetworkTaskOperation *operation,
                                                 NSHTTPURLResponse *response,
                                                 NSURLRequest *request,
                                                 void(^completionHandler)(NSURLRequest *));

/** Base NSURLSessionTask operation class.
 *
 * This is an abstract class is not intended to be used by itself. Instead, use one of its subclasses, `NetworkDataTaskOperation`, `NetworkDownloadTaskOperation`, or `NetworkUploadTaskOperation`.
 */

@interface NetworkTaskOperation : NSOperation <NSURLSessionTaskDelegate>

@property (nonatomic, weak)   NSURLSessionTask *task;
@property (nonatomic, strong) NSURLCredential *credential;

/// Did complete with error handler block

@property (nonatomic, copy)   DidCompleteWithErrorHandler       didCompleteWithErrorHandler;

/// Did receive challenge handler block

@property (nonatomic, copy)   DidReceiveChallengeHandler        didReceiveChallengeHandler;

/// Did send body data handler block

@property (nonatomic, copy)   DidSendBodyDataHandler            didSendBodyDataHandler;

/// Need new body stream handler block

@property (nonatomic, copy)   NeedNewBodyStreamHandler          needNewBodyStreamHandler;

/// Will perform HTTP redirection handler block

@property (nonatomic, copy)   WillPerformHTTPRedirectionHandler willPerformHTTPRedirectionHandler;

/** Which queue should completion/progress blocks should be called on. If `nil`, it will use `dispatch_get_main_queue()`.
 */
@property (nonatomic, strong) dispatch_queue_t completionQueue;

/** Create NetworkTaskOperation
 *
 * @param session The NSURLSession for which the task operation should be created.
 * @param request The NSURLRequest for the task operation.
 *
 * @return        Returns NetworkTaskOperation.
 */

- (instancetype)initWithSession:(NSURLSession *)session
                        request:(NSURLRequest *)request;

/** Return whether this operation respond to a challenge.
 *
 * @return YES if it can respond to challenge. NO if the session manager will try.
 */

- (BOOL)canRespondToChallenge;

/** Complete the operation.
 */

- (void)completeOperation;

@end
