#import "ViewController.h"

@interface ViewController ()
@property (strong, nonatomic) UILabel *timeLabel;
@property (strong, nonatomic) UIButton *mainButton;
@property (strong, nonatomic) UIButton *resetButton;
@property (strong, nonatomic) CADisplayLink *displayLink;
@property (assign, nonatomic) CFTimeInterval startTime;
@property (assign, nonatomic) CFTimeInterval elapsedTime;
@property (assign, nonatomic, getter=isRunning) BOOL running;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.title = @"Cronometru";
    
    [self setupUI];
    [self updateTimeLabel:0];
}

- (void)setupUI {
    // Time label
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    self.timeLabel.textColor = [UIColor whiteColor];
    self.timeLabel.font = [UIFont monospacedDigitSystemFontOfSize:80 weight:UIFontWeightMedium];
    self.timeLabel.adjustsFontSizeToFitWidth = YES;
    self.timeLabel.minimumScaleFactor = 0.5;
    [self.view addSubview:self.timeLabel];
    
    // Main button (big circular)
    self.mainButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.mainButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.mainButton.backgroundColor = [UIColor systemGreenColor];
    self.mainButton.layer.cornerRadius = 100;
    self.mainButton.clipsToBounds = YES;
    [self.mainButton setTitle:@"Start" forState:UIControlStateNormal];
    [self.mainButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.mainButton.titleLabel.font = [UIFont boldSystemFontOfSize:36];
    [self.mainButton addTarget:self action:@selector(mainButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    // Add subtle shadow
    self.mainButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.mainButton.layer.shadowOffset = CGSizeMake(0, 4);
    self.mainButton.layer.shadowOpacity = 0.3;
    self.mainButton.layer.shadowRadius = 8;
    [self.view addSubview:self.mainButton];
    
    // Reset button
    self.resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.resetButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.resetButton setTitle:@"Reset" forState:UIControlStateNormal];
    [self.resetButton setTitleColor:[UIColor systemGrayColor] forState:UIControlStateNormal];
    [self.resetButton setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
    self.resetButton.titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightMedium];
    [self.resetButton addTarget:self action:@selector(resetButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.resetButton.enabled = NO;
    [self.view addSubview:self.resetButton];
    
    // Constraints
    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        // Time label centered horizontally, above center
        [self.timeLabel.centerXAnchor constraintEqualToAnchor:guide.centerXAnchor],
        [self.timeLabel.centerYAnchor constraintEqualToAnchor:guide.centerYAnchor constant:-80],
        [self.timeLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:guide.leadingAnchor constant:40],
        [self.timeLabel.trailingAnchor constraintLessThanOrEqualToAnchor:guide.trailingAnchor constant:-40],
        
        // Main button centered below label
        [self.mainButton.centerXAnchor constraintEqualToAnchor:guide.centerXAnchor],
        [self.mainButton.topAnchor constraintEqualToAnchor:self.timeLabel.bottomAnchor constant:60],
        [self.mainButton.widthAnchor constraintEqualToConstant:200],
        [self.mainButton.heightAnchor constraintEqualToConstant:200],
        
        // Reset button below main button
        [self.resetButton.centerXAnchor constraintEqualToAnchor:guide.centerXAnchor],
        [self.resetButton.topAnchor constraintEqualToAnchor:self.mainButton.bottomAnchor constant:30],
    ]];
}

- (void)mainButtonTapped:(UIButton *)sender {
    if (self.isRunning) {
        [self stop];
    } else {
        [self start];
    }
}

- (void)start {
    self.startTime = CACurrentMediaTime() - self.elapsedTime;
    self.running = YES;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateTimer:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.mainButton.backgroundColor = [UIColor systemRedColor];
        [self.mainButton setTitle:@"Stop" forState:UIControlStateNormal];
        self.mainButton.transform = CGAffineTransformMakeScale(0.95, 0.95);
    } completion:^(BOOL finished) {
        self.mainButton.transform = CGAffineTransformIdentity;
    }];
    self.resetButton.enabled = NO;
    self.resetButton.alpha = 0.4;
}

- (void)stop {
    self.elapsedTime = CACurrentMediaTime() - self.startTime;
    self.running = NO;
    [self.displayLink invalidate];
    self.displayLink = nil;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.mainButton.backgroundColor = [UIColor systemGreenColor];
        [self.mainButton setTitle:@"Start" forState:UIControlStateNormal];
        self.mainButton.transform = CGAffineTransformMakeScale(0.95, 0.95);
    } completion:^(BOOL finished) {
        self.mainButton.transform = CGAffineTransformIdentity;
    }];
    self.resetButton.enabled = YES;
    self.resetButton.alpha = 1.0;
}

- (void)resetButtonTapped:(UIButton *)sender {
    self.elapsedTime = 0;
    [self updateTimeLabel:0];
    
    // Haptic feedback
    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [feedback prepare];
    [feedback impactOccurred];
}

- (void)updateTimer:(CADisplayLink *)link {
    CFTimeInterval current = CACurrentMediaTime() - self.startTime;
    [self updateTimeLabel:current];
}

- (void)updateTimeLabel:(CFTimeInterval)interval {
    long hours = (long)(interval / 3600);
    long minutes = (long)(fmod(interval, 3600) / 60);
    long seconds = (long)fmod(interval, 60);
    long centiseconds = (long)(fmod(interval, 1) * 100);
    
    NSString *text;
    if (hours > 0) {
        text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld.%02ld", hours, minutes, seconds, centiseconds];
    } else {
        text = [NSString stringWithFormat:@"%02ld:%02ld.%02ld", minutes, seconds, centiseconds];
    }
    self.timeLabel.text = text;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

@end