//
//  NetworkDownloadTaskOperation.h
//
//  Created by Robert Ryan on 3/5/14.
//  Copyright (c) 2014 Robert Ryan. All rights reserved.
//
//  This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
//  http://creativecommons.org/licenses/by-sa/4.0/

#import <Foundation/Foundation.h>
#import "NetworkTaskOperation.h"

@class NetworkDownloadTaskOperation;

typedef void(^DidFinishDownloadingHandler)(NetworkDownloadTaskOperation *operation,
                                           NSURL *location,
                                           NSError *error);

typedef void(^DidResumeHandler)(NetworkDownloadTaskOperation *operation,
                                int64_t offset,
                                int64_t expectedTotalBytes);

typedef void(^DidWriteDataHandler)(NetworkDownloadTaskOperation *operation,
                                   int64_t bytesWritten,
                                   int64_t totalBytesWritten,
                                   int64_t totalBytesExpectedToWrite);


/** Network Download Task Operation
 *
 * This operation is instantiated by `<NetworkManager>` when performing an download. You will not have to
 * interact directly with this class.
 */
@interface NetworkDownloadTaskOperation : NetworkTaskOperation <NSURLSessionDownloadDelegate>

/// ----------------
/// @name Properties
/// ----------------

/** Block called when the download finishes.
 
 Uses the following typedef:

    typedef void(^DidFinishDownloadingHandler)(NetworkDownloadTaskOperation *operation,
                                               NSURL *location,
                                               NSError *error);
 */
@property (nonatomic, copy) DidFinishDownloadingHandler didFinishDownloadingHandler;

/** Block called when download is resumed.
 
 Uses the following typedef:

    typedef void(^DidResumeHandler)(NetworkDownloadTaskOperation *operation,
                                    int64_t offset,
                                    int64_t expectedTotalBytes);
 */
@property (nonatomic, copy) DidResumeHandler            didResumeHandler;

/** Block called as data is downloaded and written to the file.
 
 Uses the following typedef:

    typedef void(^DidWriteDataHandler)(NetworkDownloadTaskOperation *operation,
                                       int64_t bytesWritten,
                                       int64_t totalBytesWritten,
                                       int64_t totalBytesExpectedToWrite);
 */
@property (nonatomic, copy) DidWriteDataHandler         didWriteDataHandler;

@end
