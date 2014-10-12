//
//  BlocBrowserViewController.m
//  BlocBrowser
//
//  Created by Sameer Totey on 10/11/14.
//
//

#import "BlocBrowserViewController.h"

@interface BlocBrowserViewController () <UIWebViewDelegate, UITextFieldDelegate>
@property (nonatomic, strong) UIWebView *webview;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *forwardButton;
@property (nonatomic, strong) UIButton *reloadButton;
@property (nonatomic, strong) UIButton *stopButton;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, assign) NSUInteger frameCount;
@end

@implementation BlocBrowserViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    // Do any additional setup after loading the view.
    UIView *mainView = [[UIView alloc] init];
    
    self.webview = [[UIWebView alloc] init];
    self.webview.delegate = self;
    
    self.textField = [[UITextField alloc] init];
    self.textField.keyboardType = UIKeyboardTypeURL;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.placeholder = NSLocalizedString(@"Website URL", @"Placeholder text for web browser URL field");
    self.textField.backgroundColor = [UIColor colorWithWhite:222/255.0f alpha:1];
    self.textField.delegate = self;
    
    
    self.backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.backButton setEnabled:NO];
    [self.backButton setTitle:NSLocalizedString(@"Back", @"Back Command") forState:UIControlStateNormal];
    
    self.forwardButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.forwardButton setEnabled:NO];
    [self.forwardButton setTitle:NSLocalizedString(@"Forward", @"Forward Command") forState:UIControlStateNormal];
    
    self.reloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.reloadButton setEnabled:NO];
    [self.reloadButton setTitle:NSLocalizedString(@"Reload", @"Reload Command") forState:UIControlStateNormal];
    
    self.stopButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.stopButton setEnabled:NO];
    [self.stopButton setTitle:NSLocalizedString(@"Stop", @"Stop Command") forState:UIControlStateNormal];
    
    for (UIView *viewToAdd in @[self.webview, self.textField, self.backButton, self.forwardButton, self.stopButton, self.reloadButton]) {
        [mainView addSubview:viewToAdd];
    }
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];

    self.view = mainView;
    [self addButtonTargets];
    // This is where I am calling the welcome message, maybe there is better place....
    [self welcomeMessage];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    // First calculate the dimensions
    static const CGFloat itemHeight = 50;
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat browserHeight = CGRectGetHeight(self.view.bounds) - itemHeight * 2;
    CGFloat buttonWidth = width / 4;
    
    // now assign the frames
    self.textField.frame = CGRectMake(0,0,width, itemHeight);
    self.webview.frame = CGRectMake(0, CGRectGetMaxY(self.textField.bounds), width, browserHeight);
    
    CGFloat currentButtonX = 0;
    
    for (UIButton *button in @[self.backButton, self.forwardButton, self.stopButton, self.reloadButton]) {
        button.frame = CGRectMake(currentButtonX, CGRectGetMaxY(self.webview.frame), buttonWidth, itemHeight);
        currentButtonX += buttonWidth;
    }
    
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *urlString = textField.text;
    
    NSRange spaceRange = [urlString rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    
    if (spaceRange.location != NSNotFound) {
        NSString *searchString = [NSString stringWithFormat:@"http://www.google.com/search?q=%@", urlString];
        urlString = [searchString stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    }
         
    NSURL *url = [NSURL URLWithString:urlString];
    
    if (!url.scheme) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", url]];
    }
    if (url) {
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
        [self.webview loadRequest:urlRequest];
    }
    
    return NO;
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    self.frameCount++;
    [self updateButtonsAndTitle];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.frameCount--;
    [self updateButtonsAndTitle];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (error.code != -999) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"error")
                                                    message:[error localizedDescription]
                                                   delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles: nil];
        [alert show];
    }
    
    [self updateButtonsAndTitle];
    self.frameCount--;
}

#pragma mark - Miscellaneous

- (void)updateButtonsAndTitle {
    NSString *webPageTitle = [self.webview stringByEvaluatingJavaScriptFromString:@"document.title"];
    if (webPageTitle) {
        self.title = webPageTitle;
    } else {
        self.title = self.webview.request.URL.absoluteString;
    }
    
    if (self.webview.isLoading) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
    
    self.backButton.enabled = [self.webview canGoBack];
    self.forwardButton.enabled = [self.webview canGoForward];
    self.stopButton.enabled = self.webview.isLoading;
    self.reloadButton.enabled = !self.webview.isLoading && self.webview.request.URL;
//    NSLog(@"Framecount = %d", (int)self.frameCount);
//    NSLog(@"canGoForward = %d", (int)self.webview.canGoForward);
//    NSLog(@"canGoBack = %d", (int)self.webview.canGoBack);
}

- (void)resetWebView {
    [self.webview removeFromSuperview];
    
    UIWebView *newWebView = [[UIWebView alloc] init];
    newWebView.delegate = self;
    [self.view addSubview:newWebView];
    
    self.webview = newWebView;
    [self addButtonTargets];
    self.textField.text = nil;
    [self updateButtonsAndTitle];
}

- (void)addButtonTargets {
    for (UIButton *button in @[self.backButton, self.forwardButton, self.stopButton, self.reloadButton]) {
        [button removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    }
    [self.backButton addTarget:self.webview action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [self.backButton addTarget:self.webview action:@selector(goForward) forControlEvents:UIControlEventTouchUpInside];
    [self.reloadButton addTarget:self.webview action:@selector(reload) forControlEvents:UIControlEventTouchUpInside];
    [self.stopButton addTarget:self.webview action:@selector(stopLoading) forControlEvents:UIControlEventTouchUpInside];

}

- (void)welcomeMessage {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Welcome", @"welcome title")
                                                    message:NSLocalizedString(@"Get excited to use the best browser in the market", @"browser description text")
                                                   delegate:nil cancelButtonTitle:NSLocalizedString(@"OK, I am ready", @"Welcome button title")
                                          otherButtonTitles: nil];
    [alert show];

}

@end
