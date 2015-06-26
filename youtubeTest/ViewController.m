//
//  ViewController.m
//  youtubeTest
//
//  Created by qiandong on 15/6/6.
//  Copyright (c) 2015年 qiandong. All rights reserved.
//

#import "ViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "ESGlobalDefines.h"

#import "ESPlaceholderTextView.h"

#import "GTLDefines.h"
#import "GTMOAuth2ViewControllerTouch.h"

#import "GTMHTTPUploadFetcher.h"

static NSString *const kKeychainItemName = @"GoogleAnalytics:TEST";
static NSString *const kClientId = @"865161484611-73pp638slvg47iimq44h799nhnaacn99.apps.googleusercontent.com";
static NSString *const kClientSecret = @"g8MrHz6DU7NihRjY2pmasJaO";
//static NSString *kGTLAuthScopeAnalyticsEdit1 = @"https://www.googleapis.com/auth/youtube https://www.googleapis.com/auth/youtube.readonly https://www.googleapis.com/auth/youtubepartner https://www.googleapis.com/auth/youtubepartner-channel-audit https://www.googleapis.com/auth/youtube.upload";

static NSString *kGTLAuthScopeAnalyticsEdit1 = @"https://www.googleapis.com/auth/youtube.upload";

GTMOAuth2Authentication *ga_auth;

BOOL isAuthorized;

@interface ViewController ()
{
    GTLYouTubeChannelContentDetailsRelatedPlaylists *_myPlaylists;
    GTLServiceTicket *_channelListTicket;
    NSError *_channelListFetchError;
    
    GTLYouTubePlaylistItemListResponse *_playlistItemList;
    GTLServiceTicket *_playlistItemListTicket;
    NSError *_playlistFetchError;
    
    GTLServiceTicket *_uploadFileTicket;
    NSURL *_uploadLocationURL;  // URL for restarting an upload.
}

@property (nonatomic, readonly) GTLServiceYouTube *youTubeService;

@property (strong, nonatomic) IBOutlet UIProgressView *uploadIndicator;



@end

@implementation ViewController

#pragma mark - Upload

- (void)uploadVideoFile {
    // Collect the metadata for the upload from the user interface.
    
    // Status.
    GTLYouTubeVideoStatus *status = [GTLYouTubeVideoStatus object];
//    status.privacyStatus = @"";
    
    // Snippet.
    GTLYouTubeVideoSnippet *snippet = [GTLYouTubeVideoSnippet object];
    snippet.title = nil;
    NSString *desc = @"videodesc";
    if ([desc length] > 0) {
        snippet.descriptionProperty = desc;
    }
    NSString *tagsStr = nil;
    if ([tagsStr length] > 0) {
        snippet.tags = [tagsStr componentsSeparatedByString:@","];
    }
//    snippet.categoryId = @"";
    
    GTLYouTubeVideo *video = [GTLYouTubeVideo object];
    video.status = status;
    video.snippet = snippet;
    
    [self uploadVideoWithVideoObject:video resumeUploadLocationURL:nil];
}

- (NSString *)MIMETypeForFilename:(NSString *)filename
                  defaultMIMEType:(NSString *)defaultType {
    NSString *result = defaultType;
    NSString *extension = [filename pathExtension];
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                            (__bridge CFStringRef)extension, NULL);
    if (uti) {
        CFStringRef cfMIMEType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
        if (cfMIMEType) {
            result = CFBridgingRelease(cfMIMEType);
        }
        CFRelease(uti);
    }
    return result;
}

- (void)displayAlert:(NSString *)title format:(NSString *)format, ... {
    NSString *result = format;
    if (format) {
        va_list argList;
        va_start(argList, format);
        result = [[NSString alloc] initWithFormat:format
                                        arguments:argList];
        va_end(argList);
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:result delegate:nil cancelButtonTitle:@"done" otherButtonTitles:nil, nil];
    [alert show];
}

- (void)uploadVideoWithVideoObject:(GTLYouTubeVideo *)video
           resumeUploadLocationURL:(NSURL *)locationURL {
    // Get a file handle for the upload data.
    NSString *FILE_NAME = @"IMG_0053.MP4";
    NSString *filePath = [[NSBundle mainBundle] pathForResource:FILE_NAME ofType:nil];
    
//    NSError *error = nil;
//
//    NSData *data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
//    if(data == nil && error!=nil) {
//        //Print error description
//        NSLog(@"mp4 to data err :%@",error);
//        return;
//    }
    
    if (filePath) {
        NSString *mimeType = [self MIMETypeForFilename:FILE_NAME
                                       defaultMIMEType:@"video/mp4"];
        
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
        GTLUploadParameters *uploadParameters = [GTLUploadParameters uploadParametersWithFileHandle:fileHandle MIMEType:mimeType];
        
//        GTLUploadParameters *uploadParameters = [GTLUploadParameters uploadParametersWithData:data MIMEType:mimeType];

        uploadParameters.uploadLocationURL = locationURL;
        
        GTLQueryYouTube *query = [GTLQueryYouTube queryForVideosInsertWithObject:video
                                                                            part:@"snippet,status"
                                                                uploadParameters:uploadParameters];
        
        GTLServiceYouTube *service = self.youTubeService;
        _uploadFileTicket = [service executeQuery:query
                                completionHandler:^(GTLServiceTicket *ticket,
                                                    GTLYouTubeVideo *uploadedVideo,
                                                    NSError *error) {
                                    // Callback
                                    _uploadFileTicket = nil;
                                    if (error == nil) {
                                        [self displayAlert:@"Uploaded"
                                                    format:@"Uploaded file \"%@\"",
                                         uploadedVideo.snippet.title];

                                            // Refresh the displayed uploads playlist.
//                                            [self fetchSelectedPlaylist];
                                    } else {
                                        [self displayAlert:@"Upload Failed"
                                                    format:@"%@", error];
                                    }
                                    _uploadLocationURL = nil;
                                }];
        
        typeof(self) __weak wSelf = self;
        _uploadFileTicket.uploadProgressBlock = ^(GTLServiceTicket *ticket,
                                                  unsigned long long numberOfBytesRead,
                                                  unsigned long long dataLength) {
            NSLog(@"process:%llu,%llu",dataLength,numberOfBytesRead);
            [wSelf.uploadIndicator setProgress: numberOfBytesRead*1.0f/dataLength animated:YES];
        };
        
        // To allow restarting after stopping, we need to track the upload location
        // URL.
        GTMHTTPUploadFetcher *uploadFetcher = (GTMHTTPUploadFetcher *)[_uploadFileTicket objectFetcher];
        uploadFetcher.locationChangeBlock = ^(NSURL *url) {
            _uploadLocationURL = url;
            NSLog(@"_uploadLocationURL:%@",_uploadLocationURL);
        };
        
    } else {
        // Could not read file data.
        [self displayAlert:@"File Not Found" format:@"Path: %@", filePath];
    }
}


- (IBAction)upload:(id)sender {
    [self uploadVideoFile];
    
//    CustomIOSAlertView *indicatorAlertView = [[CustomIOSAlertView alloc] init];
//    float frameRadio = UI_SCREEN_WIDTH/320;
//    
//    UploadProgressView *uploadProgressView =  [[UploadProgressView alloc] initWithFrame:CGRectMake(0, 0, 260*frameRadio, 80*frameRadio)];
//    [indicatorAlertView setContainerView:uploadProgressView];
//    [indicatorAlertView setUseMotionEffects:true];
//    [indicatorAlertView show];
}

- (IBAction)restart:(id)sender {
    [self restartUpload];
}

- (IBAction)cancel:(id)sender {
    [_uploadFileTicket cancelTicket];
    _uploadFileTicket = nil;
    
    [_uploadIndicator setProgress:0.0];
}

- (void)restartUpload {
    if (_uploadLocationURL == nil) return;

    GTLYouTubeVideo *video = [GTLYouTubeVideo object];
    
    [self uploadVideoWithVideoObject:video
             resumeUploadLocationURL:_uploadLocationURL];
}



#pragma mark - viewDidLoad
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSError *err;
    ga_auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName clientID:kClientId clientSecret:kClientSecret error:&err];
    if (!err) {
        NSLog(@"auth error:%@",err);
    }
    
    if ([ga_auth canAuthorize]) {
        [self isAuthorizedWithAuthentication:ga_auth];
    }
    
    [_uploadIndicator setProgress:0.0];
    
    
}

- (void)isAuthorizedWithAuthentication:(GTMOAuth2Authentication *)auth {
    NSLog(@"User Logged In %@", auth);
    isAuthorized = YES;
    self.youTubeService.authorizer = auth;
    // [self performSegueWithIdentifier:@"LoggedIn" sender:self];
    
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
    if (error == nil) {
        NSLog(@"NO ERROR: %@",error);
        [self isAuthorizedWithAuthentication:auth];
        ga_auth = auth;
        
    }else{
        NSLog(@"Authenticated with no Error %@ \n", error);
    }
}






- (GTLServiceYouTube *)youTubeService {
    static GTLServiceYouTube *service;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[GTLServiceYouTube alloc] init];
        service.shouldFetchNextPages = YES;
        service.retryEnabled = YES;
    });
    return service;
}


- (IBAction)login:(id)sender {
    if (!isAuthorized) {
        // Sign in.
        SEL finishedSelector = @selector(viewController:finishedWithAuth:error:);
        GTMOAuth2ViewControllerTouch *authViewController =
        [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kGTLAuthScopeYouTube
                                                   clientID:kClientId
                                               clientSecret:kClientSecret
                                           keychainItemName:kKeychainItemName
                                                   delegate:self
                                           finishedSelector:finishedSelector];
        [self presentViewController:authViewController
                           animated:YES completion:nil];
    } else {
        [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
        isAuthorized = NO;
    }
    
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
