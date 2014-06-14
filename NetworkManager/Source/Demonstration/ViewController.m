//
//  ViewController.m
//  Operation-based NSURLSession
//
//  Created by Robert Ryan on 6/10/14.
//  Copyright (c) 2014 Robert Ryan. All rights reserved.
//

#import "ViewController.h"
#import "NetworkManager.h"
#import "NetworkRequestProgressCell.h"

/** Simple request object used as the model for my tableview.
 */
@interface Request : NSObject
@property (nonatomic, strong) NSURL *url;
@property (nonatomic) CGFloat progress;
@end

@implementation Request

- (instancetype)initWithURLString:(NSString *)urlString
{
    self = [super init];
    if (self) {
        _url = [NSURL URLWithString:urlString];
        _progress = -1;
    }
    return self;
}

@end


/** Table view controller
 */
@interface ViewController ()

@property (nonatomic, strong) NetworkManager *networkManager;
@property (nonatomic, strong) NSMutableArray *requests;

@property (nonatomic, weak) NetworkDownloadTaskOperation *download;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.networkManager = [[NetworkManager alloc] init];
    self.requests = [NSMutableArray array];

//    [self addCancelAndResumeDownload];
    [self addDownloadOperations];
    [self addDataOperations];
}

/* Test cancelable request
 */
- (void)addCancelAndResumeDownload
{
    NSURL *url = [NSURL URLWithString:@"http://images.metmuseum.org/CRDImages/ep/original/DP145921.jpg"];
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *path = [documentsPath stringByAppendingPathComponent:[url lastPathComponent]];
    NSURL *fileURL = [NSURL fileURLWithPath:path];

    NetworkDownloadTaskOperation *operation = [self.networkManager downloadOperationWithURL:url didWriteDataHandler:^(NetworkDownloadTaskOperation *operation, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        float progress;
        if (totalBytesExpectedToWrite > 0) {
            progress = fmodf((float) totalBytesWritten / totalBytesExpectedToWrite, 1.0);
        } else {
            progress = fmodf((float) totalBytesWritten / 1e6, 1.0);
        }

        if (progress > 0.40) {
            [self.download cancelByProducingResumeData:^(NSData *resumeData) {
                if (resumeData) {
                    NSLog(@"successfully canceled with resume data");
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        NetworkDownloadTaskOperation *operation = [self.networkManager downloadOperationWithResumeData:resumeData didWriteDataHandler:nil didFinishDownloadingHandler:^(NetworkDownloadTaskOperation *operation, NSURL *location, NSError *error) {
                            if (error) {
                                NSLog(@"error: %@", error);
                            } else {
                                NSError *moveError;
                                if (![[NSFileManager defaultManager] moveItemAtURL:location toURL:fileURL error:&moveError]) {
                                    NSLog(@"error moving: %@", moveError);
                                } else {
                                    NSLog(@"successfully downloaded");
                                }
                            }
                        }];
                        [self.networkManager addOperation:operation];
                    });
                } else {
                    NSLog(@"no resume data returned");
                }
            }];
        }
    } didFinishDownloadingHandler:^(NetworkDownloadTaskOperation *operation, NSURL *location, NSError *error) {
        if (error) {
            NSLog(@"error in main download: %@", error);
        } else {
            NSLog(@"whoops, did not intend to reach this point");
            NSError *moveError;
            if (![[NSFileManager defaultManager] moveItemAtURL:location toURL:fileURL error:&moveError]) {
                NSLog(@"error moving: %@", moveError);
            } else {
                NSLog(@"successfully downloaded");
            }
        }
    }];

    self.download = operation;

    [self.networkManager addOperation:self.download];
}

/* Download series of images from Metropolitan Museum using `NSURLSessionDownloadTask`.
 *
 *  Included one bad URL to test error handling.
 */
- (void)addDownloadOperations
{
    NSArray *downloadURLStrings = @[@"http://images.metmuseum.org/CRDImages/ep/original/DP145921.jpg",
                                    @"http://images.metmuseum.org/CRDImages/ep/original/DP121326.jpg",
                                    @"http://images.metmuseum.org/CRDImages/ep/original/DP145399.jpg",
                                    @"http://images.metmuseum.org/CRDImages/ep/original/bad1.jpg"];

    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];

    [downloadURLStrings enumerateObjectsUsingBlock:^(NSString *urlString, NSUInteger idx, BOOL *stop) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.requests count] inSection:0];

        Request *request = [[Request alloc] initWithURLString:urlString];
        [self.requests addObject:request];

        NSOperation *operation = [self.networkManager downloadOperationWithURL:request.url didWriteDataHandler:^(NetworkDownloadTaskOperation *operation, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {

            // update cell's progress bar as we proceed

            float progress;
            if (totalBytesExpectedToWrite > 0) {
                progress = fmodf((float) totalBytesWritten / totalBytesExpectedToWrite, 1.0);
            } else {
                progress = fmodf((float) totalBytesWritten / 1e6, 1.0);
            }
            request.progress = progress;
            NetworkRequestProgressCell *cell = (id)[self.tableView cellForRowAtIndexPath:indexPath];
            [cell.progressView setProgress:progress];
        } didFinishDownloadingHandler:^(NetworkDownloadTaskOperation *operation, NSURL *location, NSError *error) {

            // indicate that download is done

            NSString *filename = [operation.task.originalRequest.URL lastPathComponent];

            if (error) {
                NSLog(@"%@: error: %@", filename, error);
                return;
            }

            NSString *path = [documentsPath stringByAppendingPathComponent:filename];
            [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:path] error:nil];
            request.progress = 1.0;
            NetworkRequestProgressCell *cell = (id)[self.tableView cellForRowAtIndexPath:indexPath];
            [cell.progressView setProgress:request.progress];
        }];
        [self.networkManager addOperation:operation];
    }];
}

/** Download series of images from NASA using `NSURLSessionDataTask`
 *
 *  Included one bad URL to test error handling.
 */

- (void)addDataOperations
{
    NSArray *downloadURLStrings = @[@"http://spaceflight.nasa.gov/gallery/images/apollo/apollo17/hires/as17-134-20380.jpg",
                                    @"http://spaceflight.nasa.gov/gallery/images/apollo/apollo17/hires/as17-140-21497.jpg",
                                    @"http://spaceflight.nasa.gov/gallery/images/apollo/apollo17/hires/as17-148-22727.jpg",
                                    @"http://spaceflight.nasa.gov/gallery/images/apollo/apollo17/hires/bad2.jpg"];

    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];

    [downloadURLStrings enumerateObjectsUsingBlock:^(NSString *urlString, NSUInteger idx, BOOL *stop) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.requests count] inSection:0];

        Request *request = [[Request alloc] initWithURLString:urlString];
        [self.requests addObject:request];

        NSOperation *operation = [self.networkManager dataOperationWithURL:request.url progressHandler:^(NetworkDataTaskOperation *operation, long long totalBytesExpected, long long bytesReceived) {

            // update cell's progress bar as we proceed

            float progress;
            if (totalBytesExpected > 0) {
                progress = fmodf((float) bytesReceived / totalBytesExpected, 1.0);
            } else {
                progress = fmodf((float) bytesReceived / 1e6, 1.0);
            }
            request.progress = progress;
            NetworkRequestProgressCell *cell = (id)[self.tableView cellForRowAtIndexPath:indexPath];
            [cell.progressView setProgress:progress];
        } completionHandler:^(NetworkTaskOperation *operation, NSData *data, NSError *error) {

            // indicate that download is done

            NSString *filename = [operation.task.originalRequest.URL lastPathComponent];
            NSString *path = [documentsPath stringByAppendingPathComponent:filename];
            if (error) {
                NSLog(@"%@: error: %@", filename, error);
                return;
            }

            if (![data writeToFile:path atomically:YES])
                NSLog(@"error writing %@", path);

            request.progress = 1.0;
            NetworkRequestProgressCell *cell = (id)[self.tableView cellForRowAtIndexPath:indexPath];
            [cell.progressView setProgress:request.progress];
        }];
        [self.networkManager addOperation:operation];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.requests count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"NetworkRequestProgressCell";
    NetworkRequestProgressCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    Request *request = self.requests[indexPath.row];
    
    cell.networkRequestLabel.text = [request.url lastPathComponent];
    [cell.progressView setProgress:request.progress];
    
    return cell;
}

@end
