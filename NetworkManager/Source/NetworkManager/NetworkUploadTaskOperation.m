//
//  NetworkUploadTaskOperation.m
//
//  Created by Robert Ryan on 3/10/14.
//  Copyright (c) 2014 Robert Ryan. All rights reserved.
//
//  This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
//  http://creativecommons.org/licenses/by-sa/4.0/

#import "NetworkUploadTaskOperation.h"

@implementation NetworkUploadTaskOperation

- (instancetype)initWithSession:(NSURLSession *)session
                        request:(NSURLRequest *)request
                           data:(NSData *)data
{
    self = [super init];
    if (self) {
        self.task = [session uploadTaskWithRequest:request fromData:data];
    }
    return self;
}

- (instancetype)initWithSession:(NSURLSession *)session
                        request:(NSURLRequest *)request
                       fromFile:(NSURL *)url
{
    self = [super init];
    if (self) {
        self.task = [session uploadTaskWithRequest:request fromFile:url];
    }
    return self;
}

@end
