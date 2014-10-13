//
//  BlocBrowserViewController.m
//  BlocBrowser
//
//  Created by Sameer Totey on 10/11/14.
//
//

#import "BlocBrowserViewController.h"
#import "AwesomeFloatingToolbar.h"

#define kWebBrowserBackString NSLocalizedString(@"Back", @"Back Command")
#define kWebBrowserForwardString NSLocalizedString(@"Forward", @"Forward Command")
#define kWebBrowserStopString NSLocalizedString(@"Stop", @"Stop Command")
#define kWebBrowserRefreshString NSLocalizedString(@"Refresh", @"Refresh Command")

@interface BlocBrowserViewController () <UIWebViewDelegate, UITextFieldDelegate, AwesomeFloatingToolbarDelegate>
@property (nonatomic, strong) UIWebView *webview;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, assign) NSUInteger frameCount;
@property (nonatomic, strong) AwesomeFloatingToolbar *awesomeFloatingToolbar;
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
    
    self.awesomeFloatingToolbar = [[AwesomeFloatingToolbar alloc] initWithFourTitles:@[kWebBrowserBackString, kWebBrowserForwardString, kWebBrowserStopString, kWebBrowserRefreshString]];
    self.awesomeFloatingToolbar.delegate = self;
    
    for (UIView *viewToAdd in @[self.webview, self.textField, self.awesomeFloatingToolbar]) {
        [mainView addSubview:viewToAdd];
    }
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];

    self.view = mainView;
    [self welcomeMessage];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    // First calculate the dimensions
    static const CGFloat itemHeight = 50;
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat browserHeight = CGRectGetHeight(self.view.bounds) - itemHeight;
    
    // now assign the frames
    self.textField.frame = CGRectMake(0,0,width, itemHeight);
    self.webview.frame = CGRectMake(0, CGRectGetMaxY(self.textField.bounds), width, browserHeight);
    self.awesomeFloatingToolbar.frame = CGRectMake(20, 100, 280, 60);
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

#pragma mark - AwesomeFloatingToolbarDelegate

- (void)floatingToolbar:(AwesomeFloatingToolbar *)toolbar didSelectButtonWithTitle:(NSString *)title {
    if (title == kWebBrowserBackString) {
        [self.webview goBack];
    } else if (title == kWebBrowserForwardString) {
        [self.webview goForward];
    } else if (title == kWebBrowserStopString) {
        [self.webview stopLoading];
    } else if (title == kWebBrowserRefreshString) {
        [self.webview reload];
    }
}

- (void)floatingToolbar:(AwesomeFloatingToolbar *)toolbar didTryToPanWithOffset:(CGPoint)offset {
    CGPoint startingPoint = toolbar.frame.origin;
    CGPoint newPoint = CGPointMake(startingPoint.x + offset.x, startingPoint.y + offset.y);
    
    CGRect potentialNewFrame = CGRectMake(newPoint.x, newPoint.y, CGRectGetWidth(toolbar.frame), CGRectGetHeight(toolbar.frame));
    if (CGRectContainsRect(self.view.bounds, potentialNewFrame)) {
        toolbar.frame = potentialNewFrame;
    }
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
    
    [self.awesomeFloatingToolbar setEnabled:self.webview.canGoBack forButtonWithTitle:kWebBrowserBackString];
    [self.awesomeFloatingToolbar setEnabled:self.webview.canGoForward forButtonWithTitle:kWebBrowserForwardString];
    [self.awesomeFloatingToolbar setEnabled:self.webview.isLoading forButtonWithTitle:kWebBrowserStopString];
    [self.awesomeFloatingToolbar setEnabled:!self.webview.isLoading && self.webview.request.URL forButtonWithTitle:kWebBrowserRefreshString];
    
}

- (void)resetWebView {
    [self.webview removeFromSuperview];
    
    UIWebView *newWebView = [[UIWebView alloc] init];
    newWebView.delegate = self;
    [self.view addSubview:newWebView];
    
    self.webview = newWebView;
    self.textField.text = nil;
    [self updateButtonsAndTitle];
}

- (void)welcomeMessage {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Welcome", @"welcome title")
                                                    message:NSLocalizedString(@"Get excited to use the best browser in the market", @"browser description text")
                                                   delegate:nil cancelButtonTitle:NSLocalizedString(@"OK, I am ready", @"Welcome button title")
                                          otherButtonTitles: nil];
    [alert show];

}

@end
