//
//  RRNetworkTaskOperation.h
//
//  Created by Robert Ryan on 1/30/14.
//  Copyright (c) 2014 Robert Ryan. All rights reserved.
//
//  This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
//  http://creativecommons.org/licenses/by-sa/4.0/

#import <Foundation/Foundation.h>
#import "NetworkTaskOperation.h"

@class NetworkDataTaskOperation;

/** Called by didReceiveResponse */

typedef void(^DidReceiveResponseHandler)(NetworkDataTaskOperation *operation,
                                         NSURLResponse *response,
                                         void(^completionHandler)(NSURLSessionResponseDisposition disposition));

/** Called by didReceiveData */

typedef void(^DidReceiveDataHandler)(NetworkDataTaskOperation *operation,
                                     NSData *data,
                                     long long totalBytesExpected,
                                     long long bytesReceived);

/** Called by didReceiveData */

typedef void(^ProgressHandler)(NetworkDataTaskOperation *operation,
                               long long totalBytesExpected,
                               long long bytesReceived);

/** Called by willCacheResponse */

typedef void(^WillCacheResponseHandler)(NetworkDataTaskOperation *operation,
                                        NSCachedURLResponse *proposedResponse,
                                        void(^completionHandler)(NSCachedURLResponse *cachedResponse));

/** Called by didBecomeDownloadTask */

typedef void(^DidBecomeDownloadTaskHandler)(NetworkDataTaskOperation *operation,
                                            NSURLSessionDownloadTask *downloadTask);

/** Operation that wraps delegate-based NSURLSessionDataDask.
 *
 * This uses a `NSURLSession` that was created with delegate, creating
 * `NSURLSessionDataTask` without `completionHandler` block. This conforms
 * to `NSURLSessionTaskDelegate` and `NSURLSessionDataDelegate`. But because
 * those delegates are specified at the session, this is used in conjunction
 * with `NSURLSessionManager` which maintains an dictionary containing
 * the operations, keyed by the task identifier, and the `NSURLSessionManager`
 * will receive delegate calls, identify the appropriate
 * `NetworkDataTaskOperation`, and pass along the delegate call
 * to the operation (if present).
 */
@interface NetworkDataTaskOperation : NetworkTaskOperation <NSURLSessionDataDelegate>

@property (nonatomic, copy) DidReceiveResponseHandler    didReceiveResponseHandler;
@property (nonatomic, copy) DidReceiveDataHandler        didReceiveDataHandler;
@property (nonatomic, copy) ProgressHandler              progressHandler;
@property (nonatomic, copy) WillCacheResponseHandler     willCacheResponseHandler;
@property (nonatomic, copy) DidBecomeDownloadTaskHandler didBecomeDownloadTaskHandler;

@end
