//
//  ViewController.m
//  SmsFourDemo
//
//  Created by Bhavesh on 4/9/15.
//  Copyright (c) 2015 cennest. All rights reserved.
//

#import "ViewController.h"
#import <SmsFour/SmsFour.h>

static NSString* kcSorceFileName = @"sample";
static NSString* kcFileExtension = @"jpg";

static uint32_t key[4] = {0x11223344, 0x11223344, 0x11223344, 0x11223344};

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *encryptButton;
@property (weak, nonatomic) IBOutlet UIButton *decryptButton;
@property (strong, nonatomic) NSString* encryptedImgsPath;
@property (strong, nonatomic) NSString* decryptedImgsPath;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    self.encryptedImgsPath = [documentsDirectory stringByAppendingPathComponent:@"/EncryptedFiles"];
    self.decryptedImgsPath = [documentsDirectory stringByAppendingPathComponent:@"/DecryptedFiles"];
    NSError* error= nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.encryptedImgsPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:self.encryptedImgsPath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.decryptedImgsPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.decryptedImgsPath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    self.encryptedImgsPath = [NSString stringWithFormat:@"%@/Encrypt.%@",self.encryptedImgsPath,kcFileExtension];
    self.decryptedImgsPath = [NSString stringWithFormat:@"%@/Decrypt.%@",self.decryptedImgsPath,kcFileExtension];
    self.decryptButton.hidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)encryptClick:(id)sender {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:kcSorceFileName ofType:kcFileExtension];
        __weak typeof(self) weakSelf = self;
        SmsFour* smsFourFile = [[SmsFour alloc]init];
        [smsFourFile encryptFile:filePath withKey:key saveFilePath:self.encryptedImgsPath completion:^(BOOL success, NSError *error) {
            if (success) {
                [weakSelf showAlertViewWithMessage:@"Encrypted task completed!"];
                weakSelf.decryptButton.hidden = NO;
                weakSelf.encryptButton.hidden = YES;
            } else {
                [weakSelf showAlertViewWithMessage:error.description];
            }
        }];
}

- (IBAction)decryptClick:(id)sender {
    SmsFour* smsFourFile = [[SmsFour alloc]init];
    __weak typeof(self) weakSelf = self;
    [smsFourFile decryptFile:self.encryptedImgsPath withKey:key saveFilePath:self.decryptedImgsPath completion:^(BOOL success, NSError *error) {
        if (success) {
            [weakSelf showAlertViewWithMessage:@"Decrypted task completed!"];
            weakSelf.decryptButton.hidden = YES;
            weakSelf.encryptButton.hidden = NO;
        } else {
            [weakSelf showAlertViewWithMessage:error.description];
        }
    }];
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

@end
