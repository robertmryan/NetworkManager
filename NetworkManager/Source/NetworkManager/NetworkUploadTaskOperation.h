//
//  NetworkUploadTaskOperation.h
//
//  Created by Robert Ryan on 3/10/14.
//  Copyright (c) 2014 Robert Ryan. All rights reserved.
//
//  This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
//  http://creativecommons.org/licenses/by-sa/4.0/

#import "NetworkTaskOperation.h"
#import "NetworkDataTaskOperation.h"

/** Network Upload Task Operation
 *
 * This operation is instantiated by `<NetworkManager>` when performing an upload. You will not have to
 * interact directly with this class.
 */
@interface NetworkUploadTaskOperation : NetworkDataTaskOperation

/// --------------------
/// @name Initialization
/// --------------------

/** Initialize upload operation
 *
 * @param session The `NSURLSession` used for the upload task.
 * @param request The `NSURLRequest`.
 * @param data    The `NSData` for the body of the request.
 *
 * @note Do not set the body of the request in the `NSMutableURLRequest` object via `setHTTPBody`, 
 *       but rather use the `data` parameter of this method.
 */
- (instancetype)initWithSession:(NSURLSession *)session
                        request:(NSURLRequest *)request
                           data:(NSData *)data;

/** Initialize upload operation
 *
 * @param session  The `NSURLSession` used for the upload task.
 * @param request  The `NSURLRequest`.
 * @param fromFile The file `NSURL` for the file containing the body of the request. This must be
 *                 fully qualified URL, not a relative URL.
 *
 * @note Do not set the body of the request in the `NSMutableURLRequest` object via `setHTTPBody`,
 *       but rather use the `data` parameter of this method.
 */
- (instancetype)initWithSession:(NSURLSession *)session
                        request:(NSURLRequest *)request
                       fromFile:(NSURL *)fromFile;

@end
