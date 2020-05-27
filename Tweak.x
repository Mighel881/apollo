//#include <RemoteLog.h>
#import "MediaRemote.h"

@interface SBMediaController
-(BOOL)isPlaying;
@end

@interface UIWindow (Apollo)
-(BOOL)_isVisible;
@end

@interface UIView (Apollo)
@property (nonatomic, assign, readwrite) CGPoint center;
-(void)pan;
@end

@interface apolloViewController : UIViewController
@property (nonatomic, assign) UIButton *playButton;
-(void)apolloPlayButtonPressed;
-(void)apolloPauseButtonPressed;
-(void)apolloPreviousButtonPressed;
-(void)apolloNextButtonPressed;
-(void)scheduleDismissWindow;
-(void)dismissWindow;
@end

static UIButton *playButton;
static UIButton *nextButton;
static UIButton *previousButton;

static UIPanGestureRecognizer *gesture;

static bool wasPlaying = false;
static bool isCurrentlyPlaying = false;
static UIWindow *apolloWindow;
static apolloViewController *viewController;

static NSTimer *dismissTimer;

float apollowViewWidth = 250;
float apollowViewHeight = 125;


static void createApolloWindow() {
  if (apolloWindow == nil) {
    apolloWindow = [[UIWindow alloc] initWithFrame:CGRectMake((([UIScreen mainScreen].bounds.size.width)/2) - apollowViewWidth/2, (([UIScreen mainScreen].bounds.size.height)/2) - apollowViewHeight/2, apollowViewWidth, apollowViewHeight)];
    apolloWindow.windowLevel = UIWindowLevelAlert;
    viewController = [[apolloViewController alloc] init];
    apolloWindow.rootViewController = viewController;
    UIView *apolloView = [[UIView alloc] initWithFrame:apolloWindow.frame];
    apolloView.layer.cornerRadius = 5;
    apolloView.alpha = 0.75;
    apolloView.layer.masksToBounds = true;
    apolloView.backgroundColor = [UIColor redColor];
    viewController.view = apolloView;
    UIButton *playButton = [UIButton buttonWithType:UIButtonTypeSystem];
    if (isCurrentlyPlaying) {
      [playButton setTitle:@"Pause" forState:UIControlStateNormal];
      [playButton addTarget:viewController action:@selector(apolloPauseButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    } else {
      [playButton setTitle:@"Play" forState:UIControlStateNormal];
      [playButton addTarget:viewController action:@selector(apolloPlayButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    playButton.frame = CGRectMake((apollowViewWidth/2)-15, (apollowViewHeight/2)-15, 30.0, 30.0);
    [playButton sizeToFit];

    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [nextButton setTitle:@"Next" forState:UIControlStateNormal];
    [nextButton addTarget:viewController action:@selector(apolloNextButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    nextButton.frame = CGRectMake((apollowViewWidth/2)+30, (apollowViewHeight/2)-15, 30.0, 30.0);
    [nextButton sizeToFit];

    UIButton *previousButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [previousButton setTitle:@"Previous" forState:UIControlStateNormal];
    [previousButton addTarget:viewController action:@selector(apolloPreviousButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    previousButton.frame = CGRectMake((apollowViewWidth/2)-70, (apollowViewHeight/2)-15, 30.0, 30.0);
    [previousButton sizeToFit];

    gesture = [[UIPanGestureRecognizer alloc] initWithTarget:viewController.view action:@selector(pan)];
    [viewController.view addGestureRecognizer:gesture];

    [viewController.view addSubview:playButton];
    [viewController.view addSubview:nextButton];
    [viewController.view addSubview:previousButton];

    [apolloWindow makeKeyAndVisible];
    apolloWindow.alpha = 0.0;
    [UIView animateWithDuration:0.3f
      animations:^{
        apolloWindow.alpha = 1.0;
      }
      completion:^(BOOL finished) {
      }
    ];
  } else {
    if(![apolloWindow _isVisible]) {
      [apolloWindow setHidden:NO];
      apolloWindow.alpha = 0.0;
      [UIView animateWithDuration:0.3f
        animations:^{
          apolloWindow.alpha = 1.0;
        }
        completion:^(BOOL finished) {
        }
      ];
    }
  }
}

static void removeApolloWindow() {
  if ([apolloWindow _isVisible]) {
    [UIView animateWithDuration:0.3f
      animations:^{
        apolloWindow.alpha = 0.0;
      }
      completion:^(BOOL finished) {
        [apolloWindow setHidden:YES];
      }
    ];
  }
}

@implementation UIView (Apollo)
-(void)pan {
  CGPoint point = [gesture locationInView:self];
  self.center = point;
}
@end

@implementation apolloViewController

-(void)apolloPlayButtonPressed {
  //RLog(@"Play button pressed");
  MRMediaRemoteSendCommand(kMRTogglePlayPause, 0);
}
-(void)apolloPauseButtonPressed {
  //RLog(@"Pause button pressed");
  MRMediaRemoteSendCommand(kMRTogglePlayPause, 0);
}
-(void)apolloNextButtonPressed {
  //RLog(@"Next button pressed");
  MRMediaRemoteSendCommand(kMRNextTrack, 0);
}
-(void)apolloPreviousButtonPressed {
  //RLog(@"Previous button pressed");
  MRMediaRemoteSendCommand(kMRPreviousTrack, 0);
}

-(void)scheduleDismissWindow {
  dismissTimer = [NSTimer scheduledTimerWithTimeInterval:5
    target:self
    selector:@selector(dismissWindow)
    userInfo:nil
    repeats:NO];
}

-(void)dismissWindow {
  removeApolloWindow();
}
@end


%hook SBMediaController
-(void)setNowPlayingInfo:(id)arg1 {
  %orig;
  if ([self isPlaying]) {
    isCurrentlyPlaying = true;
    // change text to pause
  } else {
    isCurrentlyPlaying = false;
    // change text to play
  }
  if ([self isPlaying] && wasPlaying == false) {
    wasPlaying = true;
    //Started playing
    if (dismissTimer != nil) {
      [dismissTimer invalidate];
      dismissTimer = nil;
    }
    createApolloWindow();
  } else if ([self isPlaying] == false && wasPlaying == true) {
    wasPlaying = false;
    //Stopped playing
    [viewController scheduleDismissWindow];
  }
}
%end
