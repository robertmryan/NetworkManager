//
//  NetworkManager+HTTP.m
//  NetworkManager
//
//  Created by Robert Ryan on 6/13/14.
//  Copyright (c) 2014 Robert Ryan. All rights reserved.
//

#import "NetworkManager+HTTP.h"

#if TARGET_OS_IPHONE
@import MobileCoreServices;
#endif



@implementation NetworkManager (HTTP)

- (NSString *)mimeTypeForPath:(NSString *)path
{
    // get a mime type for an extension using MobileCoreServices.framework
    
    CFStringRef extension = (__bridge CFStringRef)[path pathExtension];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, extension, NULL);
    assert(UTI != NULL);
    
    NSString *mimetype = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType));
    assert(mimetype != NULL);
    
    CFRelease(UTI);
    
    return mimetype;
}

- (NSString *)generateBoundaryString
{
    // generate boundary string
    //
    // adapted from http://developer.apple.com/library/ios/#samplecode/SimpleURLConnections
    
    CFUUIDRef  uuid;
    NSString  *uuidStr;
    
    uuid = CFUUIDCreate(NULL);
    assert(uuid != NULL);
    
    uuidStr = CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
    assert(uuidStr != NULL);
    
    CFRelease(uuid);
    
    return [NSString stringWithFormat:@"Boundary-%@", uuidStr];
}

- (NSData *)createBodyWithBoundary:(NSString *)boundary
                        parameters:(NSDictionary *)parameters
                             paths:(NSArray *)paths
                         fieldName:(NSString *)fieldName
{
    NSMutableData *httpBody = [NSMutableData data];
    
    // add params (all params are strings)
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *parameterKey, NSString *parameterValue, BOOL *stop) {
        [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", parameterKey] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"%@\r\n", parameterValue] dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    // add image data
    
    for (NSString *path in paths) {
        NSString *filename  = [path lastPathComponent];
        NSData   *data      = [NSData dataWithContentsOfFile:path];
        NSString *mimetype  = [self mimeTypeForPath:path];
        
        [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", fieldName, filename] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimetype] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:data];
        [httpBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [httpBody appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return httpBody;
}

- (NetworkUploadTaskOperation *)postUploadToURL:(NSURL *)url
                                     parameters:(NSDictionary *)parameters
                                          paths:(NSArray *)paths
                                      fieldName:(NSString *)fieldName
                                     completion:(void (^)(id responseObject, NSError *error))completion
{
    NSString *boundary = [self generateBoundaryString];
    
    // configure the request
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:NO];
    [request setTimeoutInterval:30];
    [request setHTTPMethod:@"POST"];
    
    // set content type
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    // create body
    
    NSData *httpBody = [self createBodyWithBoundary:boundary parameters:parameters paths:paths fieldName:fieldName];
    
    // setting the body of the post to the request
    
    NetworkUploadTaskOperation *operation = [self uploadOperationWithRequest:request data:httpBody didSendBodyDataHandler:nil didCompleteWithErrorHandler:^(NetworkTaskOperation *operation, NSData *data, NSError *error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *) operation.task.response;
        BOOL isJSON = NO;
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            for (NSString *headerKey in response.allHeaderFields) {
                if ([[headerKey lowercaseString] isEqualToString:@"content-type"]) {
                    if ([[response.allHeaderFields[headerKey] lowercaseString] isEqualToString:@"application/json"])
                        isJSON = YES;
                }
            }
        }
        
        if (completion) {
            if (isJSON) {
                NSError *parseError = nil;
                id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                completion(object, parseError);
            } else {
                completion(data, error);
            }
        } else if (error) {
            NSLog(@"%s: %@", __PRETTY_FUNCTION__, error);
        }
    }];
    
    [self addOperation:operation];
    
    return operation;
}

@end
