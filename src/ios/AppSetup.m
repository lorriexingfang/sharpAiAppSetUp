#import "AppSetup.h"
#import <WebKit/WebKit.h>
#import "MainViewController.h"
#import "CDVThemeableBrowser.h"
#import <SafariServices/SafariServices.h>
//#import "hotshare-Swift.h"

@interface AppSetup ()<SFSafariViewControllerDelegate>
{
    BOOL applicationWillEnterForeground;
}

@end


@implementation AppSetup

-(void)pluginInitialize{
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appSetupPluginHandleOpenURLNotification:) name:CDVPluginHandleOpenURLNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appSetupPluginDidFinishLaunchingNotification:)
                                                 name:UIApplicationDidFinishLaunchingNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(appSetupPluginWillEnterForegroundNotification:)
                                                name:UIApplicationWillEnterForegroundNotification
                                              object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(appSetupPluginOnApplicationDidBecomeActive:)
                                                name:UIApplicationDidBecomeActiveNotification
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(appSetupPluginDidEnterBackgroundNotification:)
                                                name:UIApplicationDidEnterBackgroundNotification
                                              object:nil];
}


-(void)appSetupPluginDidFinishLaunchingNotification:(NSNotification *)notification{
    NSLog(@"appSetupPluginDidFinishLaunchingNotification!");
    NSURL *redirectUrl = [NSURL URLWithString:@"https://tsdfg.tiegushi.com/redirect.html"];
    SFSafariViewController *safari = [[SFSafariViewController alloc]initWithURL:redirectUrl];
    safari.delegate = self;
    safari.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    safari.view.alpha = 0.05;
    [self.viewController presentViewController:safari animated:NO completion:nil];
    
}

- (void)handleOpenURL:(NSNotification*)notification {
    NSLog(@"appSetupPluginHandleOpenURL!");
    id url = notification.object;
    if (![url isKindOfClass:[NSURL class]]) {
        return;
    }
    NSLog(@"URL scheme:%@", [url scheme]);
    NSLog(@"URL query: %@", [url query]);
    
}

-(void)appSetupPluginWillEnterForegroundNotification:(NSNotification *)notification {
    NSLog(@"appSetupPluginWillEnterForegroundNotification!");
    applicationWillEnterForeground = true;
}

- (void)appSetupPluginDidEnterBackgroundNotification:(NSNotification *)notification{
    
    NSLog(@"appSetupPluginDidEnterBackgroundNotification!");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([self.webView isKindOfClass:[WKWebView class]]) {
        WKWebView *webview = (WKWebView *)self.webView;
        NSLog(@"webview url:%@",webview.URL.absoluteString);
        if (webview.URL) {
            [defaults setObject:webview.URL.absoluteString forKey:@"webViewURL"];
            [defaults synchronize];
        }
    }
    applicationWillEnterForeground = false;
}

- (void)appSetupPluginOnApplicationDidBecomeActive:(NSNotification *)notification {
    
    NSLog(@"appSetupPluginOnApplicationDidBecomeActive!");
    
    BOOL isBlankScreen = YES;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([[self getTopPresentedViewController] isKindOfClass:[MainViewController class]]) {
        
        MainViewController *rootViewController = (MainViewController *)[self getTopPresentedViewController];
        
        if (rootViewController.webView) {
            
            if (applicationWillEnterForeground) {
                
                [rootViewController.view bringSubviewToFront:rootViewController.webView];
            }
            if ([rootViewController.webView isKindOfClass:[WKWebView class]]) {
                
                WKWebView *webview = (WKWebView *)rootViewController.webView;
                if (applicationWillEnterForeground) {
                    if (webview.URL) {
                        NSLog(@"WKWebView is load：%@",webview.URL);
                        
                        BOOL location_is_blank = [[webview.URL absoluteString] isEqualToString:@"about:blank"];
                        
                        if (location_is_blank) {
                            return [self.viewController viewDidLoad];
                        }
                        
                        NSString *urlStr = [defaults objectForKey:@"webViewURL"];
                        
                        BOOL location_is_equal = [[webview.URL absoluteString] isEqualToString:urlStr];
                        
                        if (location_is_equal) {
                            
                            isBlankScreen = NO;
                            
                            return;
                            
                        }
                        
                        [self.viewController viewDidLoad];
                        
                    }
                    else{
                        //                        [self showAlertControllerWith:@"load a null url！Reloading" type:@"url"];
                        //                        if ([webview isLoading]) {
                        //                            [webview stopLoading];
                        //                        }
                        //                        NSString *urlStr = [defaults objectForKey:@"webViewURL"];
                        //                        NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
                        //                        [webview loadRequest:request];
                        
                        [self.viewController viewDidLoad];
                    }
                }
            }
        }
        else{
            //[self showAlertControllerWith:@"WKWebView has been killed!" type:@"killed"];
        }
    }
    else{
        if ([[self getTopPresentedViewController] isKindOfClass:[CDVThemeableBrowserNavigationController class]]) {
            
            return;
        }
        //[self showAlertControllerWith:@"MainViewController has been covered!" type:@"covered"];
    }
    
}

-(void)showAlertControllerWith:(NSString *)message type:(NSString *)type{
    //提示框
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        if ([type isEqualToString:@"covered"]) {
            
            [[self getTopPresentedViewController] dismissViewControllerAnimated:NO completion:nil];
            
            [[self getTopPresentedViewController] presentViewController:self.viewController animated:NO completion:nil];
        }
        
    }];
    
    [alertController addAction:okAction];
    
    [[self getTopPresentedViewController] presentViewController:alertController animated:YES completion:^{
        
    }];
    
}

-(UIViewController *)getTopPresentedViewController {
    UIViewController *presentingViewController = self.viewController;
    while(presentingViewController.presentedViewController != nil)
    {
        presentingViewController = presentingViewController.
        presentedViewController;
    }
    return presentingViewController;
}

-(void)getVersion:(CDVInvokedUrlCommand*)command{
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:version];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

//SFSafariViewControllerDelegate
- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller{
    [controller dismissViewControllerAnimated:NO completion:nil];
}
- (void)safariViewController:(SFSafariViewController *)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully{
    [controller dismissViewControllerAnimated:NO completion:nil];
}
@end
