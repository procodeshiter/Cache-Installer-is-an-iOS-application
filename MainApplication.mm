#import <notify.h>
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <mach/mach.h>

#define PT_ATTACH 10
#define PT_DETACH 11
#define PROC_PIDPATHINFO_MAXSIZE 1024

OBJC_EXTERN BOOL IsHUDEnabled(void);
OBJC_EXTERN void SetHUDEnabled(BOOL isEnabled);

@interface MainApplication : UIApplication
@end

@implementation MainApplication
@end

@interface RootViewController: UIViewController
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *cacheInstallerLabel;
@property (nonatomic, strong) UITextView *logTextView;
@property (nonatomic, strong) CAEmitterLayer *particleEmitter;
@end

@interface RootViewController () {
    CAGradientLayer *_backgroundGradient;
}
@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];

   

    self.cacheInstallerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
    self.cacheInstallerLabel.center = CGPointMake(self.view.center.x, self.view.center.y - 150);
    self.cacheInstallerLabel.textAlignment = NSTextAlignmentCenter;
    self.cacheInstallerLabel.textColor = [UIColor whiteColor];
    self.cacheInstallerLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
    self.cacheInstallerLabel.text = @"Cache Installer";
    [self.view addSubview:self.cacheInstallerLabel];

    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.actionButton.frame = CGRectMake(0, 0, 200, 50);
    self.actionButton.center = CGPointMake(self.view.center.x, self.view.center.y - 80);
    [self.actionButton setTitle:@"Run" forState:UIControlStateNormal];
    self.actionButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
    [self.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(startProcess) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.actionButton];

    self.actionButton.backgroundColor = [UIColor clearColor];
    self.actionButton.layer.cornerRadius = 0;
    self.actionButton.layer.masksToBounds = YES;

    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 30)];
    self.statusLabel.center = CGPointMake(self.view.center.x, self.view.center.y - 20);
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    self.statusLabel.text = @"Status: Idle";
    [self.view addSubview:self.statusLabel];

    self.logTextView = [[UITextView alloc] initWithFrame:CGRectMake(20, self.view.center.y + 20, self.view.frame.size.width - 40, 200)];
    self.logTextView.backgroundColor = [UIColor clearColor];
    self.logTextView.textColor = [UIColor whiteColor];
    self.logTextView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
    self.logTextView.editable = NO;
    self.logTextView.layer.borderColor = [UIColor clearColor].CGColor;
    self.logTextView.layer.borderWidth = 0;
    self.logTextView.layer.cornerRadius = 0;
    self.logTextView.alpha = 0;
    [self.view addSubview:self.logTextView];
}

- (void)startProcess {
    [UIView animateWithDuration:0.2 animations:^{
        self.actionButton.transform = CGAffineTransformMakeScale(0.95, 0.95);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            self.actionButton.transform = CGAffineTransformIdentity;
        }];
    }];

    self.statusLabel.text = @"Status: Processing...";
    self.logTextView.text = @"";
    [self addLog:@"[+] Starting process..."];

    NSString *fileURL = @"https://raw.githubusercontent.com/username/repository/main/data.unity.3d";
    NSString *destinationPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"data.unity.3d"];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self addLog:@"[+] Downloading file from GitHub..."];
        NSURL *url = [NSURL URLWithString:fileURL];
        NSData *fileData = [NSData dataWithContentsOfURL:url];

        if (!fileData) {
            [self addLog:@"[-] Error: Failed to download file."];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusLabel.text = @"Status: Failed";
            });
            return;
        }

        [self addLog:@"[+] Saving file to temporary directory..."];
        if (![fileData writeToFile:destinationPath atomically:YES]) {
            [self addLog:@"[-] Error: Failed to save file."];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusLabel.text = @"Status: Failed";
            });
            return;
        }

        [self addLog:@"[+] Setting file permissions..."];
        if (![self setFilePermissions:destinationPath]) {
            [self addLog:@"[-] Error: Failed to set file permissions."];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusLabel.text = @"Status: Failed";
            });
            return;
        }

        NSString *finalPath = @"/path/to/destination/data.unity.3d";
        NSString *backupPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"backup_data.unity.3d"];

        [self addLog:@"[+] Backing up original file..."];
        if ([[NSFileManager defaultManager] fileExistsAtPath:finalPath]) {
            NSError *error = nil;
            if (![[NSFileManager defaultManager] copyItemAtPath:finalPath toPath:backupPath error:&error]) {
                [self addLog:[NSString stringWithFormat:@"[-] Error: %@", error.localizedDescription]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.statusLabel.text = @"Status: Failed";
                });
                return;
            }
        }

        [self addLog:@"[+] Moving file to destination..."];
        NSError *error = nil;
        if ([[NSFileManager defaultManager] moveItemAtPath:destinationPath toPath:finalPath error:&error]) {
            [self addLog:@"[+] File moved successfully."];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusLabel.text = @"Status: Success";
                [self launchStandoff2];
            });

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self addLog:@"[+] Restoring original file..."];
                NSError *restoreError = nil;
                if ([[NSFileManager defaultManager] moveItemAtPath:backupPath toPath:finalPath error:&restoreError]) {
                    [self addLog:@"[+] Original file restored."];
                } else {
                    [self addLog:[NSString stringWithFormat:@"[-] Error: %@", restoreError.localizedDescription]];
                }
            });
        } else {
            [self addLog:[NSString stringWithFormat:@"[-] Error: %@", error.localizedDescription]];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusLabel.text = @"Status: Failed";
            });
        }
    });
}

- (BOOL)setFilePermissions:(NSString *)filePath {
    NSDictionary *attributes = @{
        NSFilePosixPermissions: @(0666)
    };
    NSError *error = nil;
    if (![[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:filePath error:&error]) {
        NSLog(@"Error setting permissions: %@", error.localizedDescription);
        return NO;
    }
    return YES;
}

- (void)launchStandoff2 {
    NSString *bundleID = @"com.axlebolt.standoff2";
    NSURL *appURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://", bundleID]];
    if ([[UIApplication sharedApplication] canOpenURL:appURL]) {
        [[UIApplication sharedApplication] openURL:appURL options:@{} completionHandler:nil];
        [self addLog:@"[+] Standoff 2 launched successfully."];
    } else {
        [self addLog:@"[-] Error: Standoff 2 not found."];
    }
}

- (void)addLog:(NSString *)logMessage {
    if (self.logTextView.alpha == 0) {
        [UIView animateWithDuration:0.5 animations:^{
            self.logTextView.alpha = 1;
        }];
    }

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];

    NSString *currentLogs = self.logTextView.text;
    self.logTextView.text = [NSString stringWithFormat:@"%@\n[%@] %@", currentLogs, timestamp, logMessage];

    NSRange range = NSMakeRange(self.logTextView.text.length - 1, 1);
    [self.logTextView scrollRangeToVisible:range];

    CATransition *animation = [CATransition animation];
    animation.duration = 0.5;
    animation.type = kCATransitionFade;
    [self.logTextView.layer addAnimation:animation forKey:nil];
}

@end

@interface MainApplicationDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation MainApplicationDelegate {
    RootViewController *_rootViewController;
}

- (instancetype)init {
    if (self = [super init]) {
        os_log_debug(OS_LOG_DEFAULT, "- [MainApplicationDelegate init]");
    }
    return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary <UIApplicationLaunchOptionsKey, id> *)launchOptions {
    os_log_debug(OS_LOG_DEFAULT, "- [MainApplicationDelegate application:%{public}@ didFinishLaunchingWithOptions:%{public}@]", application, launchOptions);
    
    _rootViewController = [[RootViewController alloc] init];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:_rootViewController];
    [self.window makeKeyAndVisible];

    return YES;
}

@end