//
//  AwesomeFloatingToolbar.m
//  BlocBrowser
//
//  Created by Sameer Totey on 10/11/14.
//
//

#import "AwesomeFloatingToolbar.h"

@interface AwesomeFloatingToolbar()
@property (nonatomic, strong)NSArray *currentTitles;
@property (nonatomic, strong)NSArray *colors;
@property (nonatomic, strong)NSArray *labels;
@property (nonatomic, weak)UILabel *currentLabel;

@end

@implementation AwesomeFloatingToolbar

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFourTitles:(NSArray *)titles {
    self = [super init];
    
    if (self) {
        // save the titles and save the four colors
        self.currentTitles = titles;
        self.colors = @[[UIColor colorWithRed:199/255.0 green:158/255.0 blue:203/255.0 alpha:1],
                        [UIColor colorWithRed:255/255.0 green:105/255.0 blue:97/255.0 alpha:1],
                        [UIColor colorWithRed:222/255.0 green:165/255.0 blue:164/255.0 alpha:1],
                        [UIColor colorWithRed:255/255.0 green:179/255.0 blue:71/255.0 alpha:1]];
        
        NSMutableArray *labelsArray = [[NSMutableArray alloc] init];
        
        // Make the for labels
        
        for (NSString *currentTitle in self.currentTitles) {
            UILabel *label = [[UILabel alloc] init];
            label.userInteractionEnabled = NO;
            label.alpha = 0.25;
            
            NSUInteger currentTitleIndex = [self.currentTitles indexOfObject:currentTitle];  // 0 thru 3
            NSString *titleForThisLabel = [self.currentTitles objectAtIndex:currentTitleIndex];  // same as currentTitle
            UIColor *colorForThisLabel = [ self.colors objectAtIndex:currentTitleIndex];
            
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont systemFontOfSize:10];
            label.text = titleForThisLabel;
            label.backgroundColor = colorForThisLabel;
            label.textColor = [UIColor whiteColor];
            
            [labelsArray addObject:label];
        }
        
        self.labels = labelsArray;
        
        for (UILabel *thisLabel in self.labels) {
            [self addSubview:thisLabel];
        }
        
    }
    
    return self;
}

- (void)layoutSubviews {
    // set the frame for the 4 label
    for (UILabel *thisLabel in self.labels) {
        NSUInteger currentLabelIndex = [self.labels indexOfObject:thisLabel];
        
        CGFloat labelHeight = CGRectGetHeight(self.bounds) / 2;
        CGFloat labelWidth = CGRectGetWidth(self.bounds) / 2;
        CGFloat labelX = 0;
        CGFloat labelY = 0;
        
        // adjust labelX and labelY for each label
        if (currentLabelIndex < 2) {            // 0, 1 go to top row
            labelY = 0;
        } else {
            labelY = labelHeight;                // 2, 3 go to the botton row
        }
        
        if (currentLabelIndex % 2 == 0) {      // even numbers (0, 2) go to left
            labelX = 0;
        } else {
            labelX = labelWidth;              // odd number (1, 3) go to right
        }
        thisLabel.frame = CGRectMake(labelX, labelY, labelWidth, labelHeight);
    }
    
}

#pragma mark - Button Enabling

- (void)setEnabled:(BOOL)enabled forButtonWithTitle:(NSString *)title {
    NSUInteger index = [self.currentTitles indexOfObject:title];
    
    if (index != NSNotFound) {
        UILabel *label = [self.labels objectAtIndex:index];
        label.userInteractionEnabled = enabled;
        label.alpha = enabled ? 1.0 : .25;
    }
}

#pragma mark - Touch Handling

- (UILabel *)labelFromTouches:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    UIView *subview = [self hitTest:location withEvent:event];
    return (UILabel *)subview;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UILabel *label = [self labelFromTouches:touches withEvent:event];
    
    self.currentLabel = label;
    self.currentLabel.alpha = 0.5;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UILabel *label = [self labelFromTouches:touches withEvent:event];
    
    if (self.currentLabel != label) {
        self.currentLabel.alpha = 1;         // the label being touched is no longer the initial label
    } else {
        self.currentLabel.alpha = 0.5;      // the label being touched is the initial label
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UILabel *label = [self labelFromTouches:touches withEvent:event];
    // There is a chance that the user clicks the disabled label, in that case the class of the label will be AwesomeFloatingToolbar
    if (self.currentLabel == label && [label isKindOfClass:[UILabel class]]) {
        NSLog(@"label tapped %@", self.currentLabel.text);
        if ([self.delegate respondsToSelector:@selector(floatingToolbar:didSelectButtonWithTitle:)]) {
            [self.delegate floatingToolbar:self didSelectButtonWithTitle:self.currentLabel.text];
        }
    }
    self.currentLabel.alpha = 1;
    self.currentLabel = nil;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    self.currentLabel.alpha = 1;
    self.currentLabel= nil;
}

@end
