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

typedef void(^DidReceiveResponseHandler)(NetworkDataTaskOperation *operation,
                                         NSURLResponse *response,
                                         void(^completionHandler)(NSURLSessionResponseDisposition disposition));

typedef void(^DidReceiveDataHandler)(NetworkDataTaskOperation *operation,
                                     NSData *data,
                                     long long totalBytesExpected,
                                     long long bytesReceived);

typedef void(^ProgressHandler)(NetworkDataTaskOperation *operation,
                               long long totalBytesExpected,
                               long long bytesReceived);

typedef void(^WillCacheResponseHandler)(NetworkDataTaskOperation *operation,
                                        NSCachedURLResponse *proposedResponse,
                                        void(^completionHandler)(NSCachedURLResponse *cachedResponse));

typedef void(^DidBecomeDownloadTaskHandler)(NetworkDataTaskOperation *operation,
                                            NSURLSessionDownloadTask *downloadTask);

/** Operation that wraps delegate-based NSURLSessionDataDask.
 *
 * This is a `<NetworkTaskOperation>` subclass instantiated by `<NetworkManager>` method
 * `dataOperationWithRequest:progressHandler:completionHandler:`.
 * This implements the `NSURLSessionTaskDelegate` methods, which the
 * `<NetworkManager>` will invoke as it (the actual task delegate) 
 * receives its delegate calls.
 */
@interface NetworkDataTaskOperation : NetworkTaskOperation <NSURLSessionDataDelegate>

/// ----------------
/// @name Properties
/// ----------------

/** Called by `NSURLSessionDataDelegate` method `URLSession:dataTask:didReceiveResponse:completionHandler:`.

 Uses the following typdef:

    typedef void(^DidReceiveResponseHandler)(NetworkDataTaskOperation *operation,
                                             NSURLResponse *response,
                                             void(^completionHandler)(NSURLSessionResponseDisposition disposition));
 */

@property (nonatomic, copy) DidReceiveResponseHandler    didReceiveResponseHandler;

/** Called by `NSURLSessionDataDelegate` method `URLSession:dataTask:didReceiveData:`.

 Use this block if you do not want the `NetworkDataTaskOperation` to build a `NSData` object
 with the entire response, but rather if you're going to handle the data as it comes in yourself
 (e.g. you have your own streaming method or are going to be processing the response as it comes
 in, rather than waiting for the entire response).
 
 Uses the following typedef:
 
    typedef void(^DidReceiveDataHandler)(NetworkDataTaskOperation *operation,
                                         NSData *data,
                                         long long totalBytesExpected,
                                         long long bytesReceived);

 @note The `totalBytesExpected` parameter of this block is provided by the server, and as such, it is not entirely reliable. Also note that if it could not be determined, `totalBytesExpected` may be reported as -1.

 @see progressHandler

 */

@property (nonatomic, copy) DidReceiveDataHandler        didReceiveDataHandler;

/** Called by `NSURLSessionDataDelegate` method `URLSession:dataTask:didReceiveData:`

 Use this block if you do want the `NetworkDataTaskOperation` to build a `NSData` object
 with the entire response, but simply want to be notified of its progress.

 Uses the following typedef:

    typedef void(^ProgressHandler)(NetworkDataTaskOperation *operation,
                                   long long totalBytesExpected,
                                   long long bytesReceived);

 @note The `totalBytesExpected` parameter of this block is provided by the server, and as such, it is not entirely reliable. Also note that if it could not be determined, `totalBytesExpected` may be reported as -1.

 @see didReceiveDataHandler

 */

@property (nonatomic, copy) ProgressHandler              progressHandler;

/** Called by `NSURLSessionDataDelegate` method `URLSession:dataTask:willCacheResponse:completionHandler:` 
 
 Uses the following typedef:
 
    typedef void(^WillCacheResponseHandler)(NetworkDataTaskOperation *operation,
                                            NSCachedURLResponse *proposedResponse,
                                            void(^completionHandler)(NSCachedURLResponse *cachedResponse));
*/

@property (nonatomic, copy) WillCacheResponseHandler     willCacheResponseHandler;

/** Called by `NSURLSessionDataDelegate` method `URLSession:dataTask:didBecomeDownloadTask:` 
 
 Uses the following typdef:

    typedef void(^DidBecomeDownloadTaskHandler)(NetworkDataTaskOperation *operation,
                                                NSURLSessionDownloadTask *downloadTask);
*/

@property (nonatomic, copy) DidBecomeDownloadTaskHandler didBecomeDownloadTaskHandler;

@end
