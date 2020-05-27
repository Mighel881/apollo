#include <RemoteLog.h>
#import "MediaRemote.h"

#define kBundlePath @"/Library/Application Support/ApolloBundle.bundle"

@interface SBMediaController
-(BOOL)isPlaying;
@end

@interface UIWindow (Apollo)
-(BOOL)_isVisible;
@end

/*@interface UIView (Apollo)
@property (nonatomic, assign, readwrite) CGPoint center;
-(void)pan;
@end*/

@interface apolloViewController : UIViewController
@property (nonatomic, assign) UIButton *playButton;
-(void)apolloPlayButtonPressed;
-(void)apolloPauseButtonPressed;
-(void)apolloPreviousButtonPressed;
-(void)apolloNextButtonPressed;
-(void)scheduleDismissWindow;
-(void)dismissWindow;
-(void)move:(UIPanGestureRecognizer *)recognizer;
@end

static UIButton *playButton;
static UIButton *nextButton;
static UIButton *previousButton;
static UIImage *playImg;
static UIImage *pauseImg;


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
    apolloView.alpha = 1;
    apolloView.layer.masksToBounds = true;
    apolloView.backgroundColor = [UIColor clearColor];

    UIVisualEffect *blurEffect;
    // wont change on the fly, but dismissing/invoking the player again should refresh it
    // right, we can add another method to do it on the fly
    if (apolloWindow.traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
      blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    } else if (apolloWindow.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
      blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    }
    UIVisualEffectView *visualEffectView;
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.frame = apolloView.bounds;
    [apolloView addSubview:visualEffectView];
    viewController.view = apolloView;

    NSBundle *bundle = [[NSBundle alloc] initWithPath:kBundlePath];
    NSString *playImgPath = [bundle pathForResource:@"play" ofType:@"png"];
    playImg = [UIImage imageWithContentsOfFile:playImgPath];

    NSString *pauseImgPath = [bundle pathForResource:@"pause" ofType:@"png"];
    pauseImg = [UIImage imageWithContentsOfFile:pauseImgPath];

    NSString *nextImgPath = [bundle pathForResource:@"next" ofType:@"png"];
    UIImage *nextImg = [UIImage imageWithContentsOfFile:nextImgPath];

    NSString *previousImgPath = [bundle pathForResource:@"previous" ofType:@"png"];
    UIImage *previousImg = [UIImage imageWithContentsOfFile:previousImgPath];

    UIButton *playButton = [UIButton buttonWithType:UIButtonTypeSystem];
    if (isCurrentlyPlaying) {
      [playButton setImage:pauseImg forState:UIControlStateNormal];
      RLog(@"setting pauseImg");
      [playButton addTarget:viewController action:@selector(apolloPauseButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    } else {
      [playButton setImage:playImg forState:UIControlStateNormal];
      RLog(@"setting playImg");
      [playButton addTarget:viewController action:@selector(apolloPlayButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    playButton.frame = CGRectMake((apollowViewWidth/2)-15, (apollowViewHeight/2)-15, 30.0, 30.0);
    [[playButton imageView] setContentMode:UIViewContentModeScaleAspectFit];
    playButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    playButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;

    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [nextButton setImage:nextImg forState:UIControlStateNormal];
    [nextButton addTarget:viewController action:@selector(apolloNextButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    nextButton.frame = CGRectMake((apollowViewWidth/2)+30, (apollowViewHeight/2)-15, 30.0, 30.0);
    nextButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    nextButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;

    UIButton *previousButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [previousButton setImage:previousImg forState:UIControlStateNormal];
    [previousButton addTarget:viewController action:@selector(apolloPreviousButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    previousButton.frame = CGRectMake((apollowViewWidth/2)-70, (apollowViewHeight/2)-15, 30.0, 30.0);
    previousButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    previousButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;

    UIPanGestureRecognizer *gesture = [[UIPanGestureRecognizer alloc] initWithTarget:viewController action:@selector(move:)];
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

@implementation apolloViewController
-(void)move:(UIPanGestureRecognizer *)recognizer {
  CGPoint point = [recognizer locationInView:self.view];
  self.view.center = point;
}
-(void)apolloPlayButtonPressed {
  MRMediaRemoteSendCommand(kMRTogglePlayPause, 0);
}
-(void)apolloPauseButtonPressed {
  MRMediaRemoteSendCommand(kMRTogglePlayPause, 0);
}
-(void)apolloNextButtonPressed {
  MRMediaRemoteSendCommand(kMRNextTrack, 0);
}
-(void)apolloPreviousButtonPressed {
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
    [playButton setImage:pauseImg forState:UIControlStateNormal];
    RLog(@"setting pauseImg");
  }else {
    isCurrentlyPlaying = false;
    [playButton setImage:playImg forState:UIControlStateNormal];
    RLog(@"setting playImg");
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
