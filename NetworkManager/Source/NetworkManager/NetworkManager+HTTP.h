//
//  NetworkManager+HTTP.h
//  NetworkManager
//
//  Created by Robert Ryan on 6/13/14.
//  Copyright (c) 2014 Robert Ryan. All rights reserved.
//

#import "NetworkManager.h"

/** Utility Methods to simplify the process of creating certain HTTP requests
 */
@interface NetworkManager (HTTP)

/// -----------------------------------------------
/// @name HTTP request utility methods
/// -----------------------------------------------

/** Prepare and initiate multipart/form-data request with files
 *
 * @param url          URL to use for POST request.
 * @param parameters   `NSDictionary` for parameters to add to POST request; may be `nil` if no additional parameters.
 * @param paths        `NSArray` of paths of files to add to request; should be fully qualified file paths.
 * @param fieldName    `NSString` of field name to use for files specified in `paths`.
 * @param completion   Block to be invoked when POST request completes (or fails).
 *
 * @return             The operation that has been started.
 */
- (NetworkUploadTaskOperation *)postUploadToURL:(NSURL *)url
                                     parameters:(NSDictionary *)parameters
                                          paths:(NSArray *)paths
                                      fieldName:(NSString *)fieldName
                                     completion:(void (^)(id responseObject, NSError *error))completion;

/** Determine mime type on basis of file extension
 *
 * @param  path        The path of the file being uploaded
 *
 * @return             `NSString` of mime representation
 */
- (NSString *)mimeTypeForPath:(NSString *)path;

/** Generate random boundary string.
 *
 * Every time you call this method, you will receive new random boundary string, so call this method only once for each request.
 *
 * @return Random boundary string.
 */
- (NSString *)generateBoundaryString;

@end
