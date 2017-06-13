#import "AppSetup.h"
#import <WebKit/WebKit.h>
#import "MainViewController.h"
#import "CDVThemeableBrowser.h"
#import <SafariServices/SafariServices.h>
//#import "hotshare-Swift.h"

@interface AppSetup ()<SFSafariViewControllerDelegate>
{
    BOOL applicationWillEnterForeground;
    SFSafariViewController *safari;
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *_needLaunchSFSafariViewController = [defaults objectForKey:@"hadLaunchedSFSafariViewController"];
    if ([_needLaunchSFSafariViewController isEqualToString:@"true"]) {
        return;
    }
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
        NSURL *redirectUrl = [NSURL URLWithString:@"https://tsdfg.tiegushi.com/deeplink_redirect"];
        safari = [[SFSafariViewController alloc]initWithURL:redirectUrl];
        //SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:redirectUrl entersReaderIfAvailable:YES];
        safari.delegate = self;
        safari.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [safari.view setUserInteractionEnabled:NO];
        safari.view.alpha = 0.05;
        [self.viewController presentViewController:safari animated:NO completion:nil];
        [defaults setObject:@"true" forKey:@"hadLaunchedSFSafariViewController"];
        [defaults synchronize];
    }
}

- (void)handleOpenURL:(NSNotification*)notification {
    NSLog(@"appSetupPluginHandleOpenURL!");
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayMethod:) object:safari];
    [safari dismissViewControllerAnimated:NO completion:nil];
    id url = notification.object;
    if (![url isKindOfClass:[NSURL class]]) {
        return;
    }
    NSLog(@"URL scheme:%@", [url scheme]);
    NSLog(@"URL query: %@", [url query]);
    NSArray *ary = [[url query] componentsSeparatedByString:@"&"];
    NSMutableString *params = [NSMutableString string];
    for (NSString *subStr in ary) {
        NSArray *tempAry = [subStr componentsSeparatedByString:@"="];
        if (tempAry && tempAry.count > 1) {
            [params appendFormat:@"'%@':'%@',",tempAry[0],tempAry[1]];
        }
    }
    NSString *params1 = [params substringToIndex:params.length-1];
    NSLog(@"URL params: %@", params1);
    NSString *data = [NSString stringWithFormat:@"var cookie = {'url':'%@','scheme':'%@','path':'%@','params':{%@}}",[url absoluteString],[url scheme],[url path],params1];
    if ([self.webView isKindOfClass:[WKWebView class]]) {
        WKWebView *webview = (WKWebView *)self.webView;
        [webview evaluateJavaScript:[NSString stringWithFormat: @"%@;window.didLaunchAppFromDerferedLink(cookie)",data] completionHandler:nil];
    }
    
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
    [self performSelector:@selector(delayMethod:) withObject:controller afterDelay:2.0];
}
-(void)delayMethod:(SFSafariViewController *)controller {
    [controller dismissViewControllerAnimated:NO completion:nil];
}
@end