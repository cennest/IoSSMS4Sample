//
//  ViewController.m
//  SmsFourDemo
//
//  Created by Bhavesh on 4/9/15.
//  Copyright (c) 2015 cennest. All rights reserved.
//

#import <SmsFour/SmsFour.h>

#import "ViewController.h"
#import "btSimplePopUP.h"
#import "RTSpinKitView.h"

static NSString* const kcKey = @"DemoKey";
static NSString* const kcOriginalFileFormate = @"%@/Original.%@";
static NSString* const kcEncryptFileFormate = @"%@/Encrypt.%@";
static NSString* const kcDecryptFileFormate = @"%@/Decrypt.%@";

@interface ViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *encryptButton;
@property (weak, nonatomic) IBOutlet UIButton *decryptButton;
@property (weak, nonatomic) IBOutlet UIButton *loadFileBtn;
@property (strong, nonatomic) NSString* encryptedImgsPath;
@property (strong, nonatomic) NSString* decryptedImgsPath;
@property (strong, nonatomic) NSString* originalImgsPath;
@property (strong, nonatomic) btSimplePopUP* popUp;
@property (weak, nonatomic) IBOutlet UIView *dimView;
@property (strong, nonatomic) RTSpinKitView* spinner;
@property (strong, nonatomic) NSString* fileExtension;
@property (strong, nonatomic) NSURL* iCloudUrl;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    self.encryptedImgsPath = [documentsDirectory stringByAppendingPathComponent:@"/EncryptedFiles"];
    self.decryptedImgsPath = [documentsDirectory stringByAppendingPathComponent:@"/DecryptedFiles"];
    self.originalImgsPath = [documentsDirectory stringByAppendingPathComponent:@"/OriginalFiles"];
    NSError* error= nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.encryptedImgsPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:self.encryptedImgsPath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.decryptedImgsPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.decryptedImgsPath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.originalImgsPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.originalImgsPath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    self.encryptButton.hidden = YES;
    self.decryptButton.hidden = YES;
    [self addPopup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)addPopup
{
    NSArray* popUpImages = @[ [UIImage imageNamed:@"camera.png"],[UIImage imageNamed:@"gallary.png"],[UIImage imageNamed:@"cloudUp.png"]];
    NSArray* popUpTitles = @[@"Camera",@"Gallery",@"iCloud"];
    NSArray* popUpActions =@[
                             ^{ [self openCamera]; },
                             ^{ [self openGallary]; },
                             ^{ [self openiCloud]; }
                              ];
    self.popUp = [[btSimplePopUP alloc]initWithItemImage:popUpImages andTitles:popUpTitles andActionArray:popUpActions addToViewController:self];
    [self.view addSubview:self.popUp];
    [self.popUp setPopUpStyle:BTPopUpStyleDefault];
    [self.popUp setPopUpBorderStyle:BTPopUpBorderStyleDefaultNone];
    [self.popUp setPopUpBackgroundColor:[UIColor colorWithRed:0.1 green:0.2 blue:0.6 alpha:0.7]];
}


- (IBAction)encryptClick:(id)sender {
    if (self.iCloudUrl) {
        [self encryptUsingFileUrl];
    } else {
        [self encryptUsingFilePathString];
    }
    
}

-(void)encryptUsingFilePathString
{
    NSString* filePath = [NSString stringWithFormat:kcOriginalFileFormate,self.originalImgsPath,self.fileExtension];
    NSString* destinationPath = [NSString stringWithFormat:kcEncryptFileFormate,self.encryptedImgsPath,self.fileExtension];
    __weak typeof(self) weakSelf = self;
    SmsFour* smsFourFile = [[SmsFour alloc]init];
    uint32_t* key =[smsFourFile createKeyFormString:kcKey];
    [self startActivityIndicator];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [smsFourFile encryptFile:filePath withKey:key saveFilePath:destinationPath completion:^(BOOL success, NSError *error) {
            free(key);
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf stopActIndicator];
                if (success) {
                    [weakSelf showAlertViewWithMessage:@"Encrypted task completed!"];
                    weakSelf.decryptButton.hidden = NO;
                    weakSelf.encryptButton.hidden = YES;
                } else {
                    [weakSelf showAlertViewWithMessage:error.description];
                    weakSelf.decryptButton.hidden = NO;
                    weakSelf.encryptButton.hidden = YES;
                }});
        }];
    });
    
}

-(void)encryptUsingFileUrl
{
    NSString* destinationPath = [NSString stringWithFormat:kcEncryptFileFormate,self.encryptedImgsPath,self.fileExtension];
    NSLog(@"iCould url : - %@",self.iCloudUrl);
    __weak typeof(self) weakSelf = self;
    SmsFour* smsFourFile = [[SmsFour alloc]init];
    [self startActivityIndicator];
    uint32_t* key =[smsFourFile createKeyFormString:kcKey];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [smsFourFile encryptFileFromUrl:self.iCloudUrl withKey:key saveFilePath:destinationPath completion:^(BOOL success, NSError *error) {
            free(key);
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf stopActIndicator];
                if (success) {
                    [weakSelf showAlertViewWithMessage:@"Encrypted task completed!"];
                    weakSelf.decryptButton.hidden = NO;
                    weakSelf.encryptButton.hidden = YES;
                } else {
                    [weakSelf showAlertViewWithMessage:error.description];
                }});
        }];
    });
    
}


- (IBAction)decryptClick:(id)sender {
    
    NSString* sourceFile = [NSString stringWithFormat:kcEncryptFileFormate,self.encryptedImgsPath,self.fileExtension];
    NSString* destinationPath = [NSString stringWithFormat:kcDecryptFileFormate,self.decryptedImgsPath,self.fileExtension];
    SmsFour* smsFourFile = [[SmsFour alloc]init];
    __weak typeof(self) weakSelf = self;
    [self startActivityIndicator];
    uint32_t* key =[smsFourFile createKeyFormString:kcKey];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [smsFourFile decryptFile:sourceFile withKey:key saveFilePath:destinationPath completion:^(BOOL success, NSError *error) {
            free(key);
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf stopActIndicator];
                if (success) {
                    [weakSelf showAlertViewWithMessage:@"Decrypted task completed!"];
                    weakSelf.decryptButton.hidden = YES;
                    weakSelf.loadFileBtn.hidden = NO;
                } else {
                    [weakSelf showAlertViewWithMessage:error.description];
                }
            });
            
        }];
    });
    
}

- (IBAction)loadFileBtnClicked:(id)sender {
    self.iCloudUrl = nil;
    [self.popUp show:BTPopUPAnimateNone];
}


-(void)openCamera
{
    UIImagePickerController* imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType =  UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:imagePickerController animated:NO completion:nil];
}

-(void)openGallary
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc]init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:imagePickerController animated:NO completion:nil];
}

-(void)openiCloud
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        //older than iOS 8 code here
        [self showAlertViewWithMessage:@"iCloud is supported only in ios 8 version's device."];
    } else {
        //iOS 8 specific code here
        UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.content"] inMode:UIDocumentPickerModeOpen];
        documentPicker.delegate = self;
        documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:documentPicker animated:YES completion:nil];
    }
}

-(void)startActivityIndicator
{
    [self.dimView setHidden:NO];
    if (self.spinner==nil) {
        self.spinner=[[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleWave color:[UIColor whiteColor]];
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        self.spinner.center = CGPointMake(CGRectGetMidX(screenBounds), CGRectGetMidY(screenBounds));
        [self.dimView addSubview:self.spinner];
        [self.parentViewController.view bringSubviewToFront:self.dimView];
    }
    [self.spinner startAnimating];
    [self.spinner setHidden:NO];
}

-(void)stopActIndicator
{
    [self.spinner stopAnimating];
    [self.dimView setHidden:YES];
    [self.spinner setHidden:YES];
}

-(void)saveOriginalCameraImage:(UIImage*)image
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *pngData = UIImagePNGRepresentation(image);
        NSString* cameraImagePath = [NSString stringWithFormat:kcOriginalFileFormate,self.originalImgsPath,self.fileExtension];
        [pngData writeToFile:cameraImagePath atomically:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf stopActIndicator];
            //[weakSelf showAlertViewWithMessage:@"File saved!"];
            weakSelf.loadFileBtn.hidden = YES;
            weakSelf.encryptButton.hidden = NO;
        });
    });
    
}

-(void)showAlertViewWithMessage:(NSString*)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:message
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    [self startActivityIndicator];
    self.fileExtension = @"png";
    [picker dismissModalViewControllerAnimated:NO];
    [self saveOriginalCameraImage:image];
}



-(void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url
{
    if (controller.documentPickerMode == UIDocumentPickerModeOpen) {
        [url startAccessingSecurityScopedResource];
        NSString *path = [url path];
        self.fileExtension = [path pathExtension];
        self.iCloudUrl=url;
        if (url) {
            //[self showAlertViewWithMessage:@"Got file url!"];
            self.loadFileBtn.hidden = YES;
            self.encryptButton.hidden = NO;
        } else {
            [self showAlertViewWithMessage:@"File url is NULL!"];
        }
    }
}

@end
