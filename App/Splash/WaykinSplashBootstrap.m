#import <UIKit/UIKit.h>

static UIWindow *WaykinSplashWindow;
static id WaykinLaunchObserver;

static BOOL WaykinIsUITesting(void) {
    return [[[NSProcessInfo processInfo] arguments] containsObject:@"-WAYKIN_UI_TESTING"];
}

static BOOL WaykinUsesDarkDayArtwork(NSDate *date) {
    NSInteger hour = [[NSCalendar currentCalendar] component:NSCalendarUnitHour fromDate:date];
    return hour >= 7 && hour < 19;
}

static UIColor *WaykinColor(CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha) {
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

static CAShapeLayer *WaykinCircleLayer(CGRect frame, UIColor *strokeColor, CGFloat lineWidth) {
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = frame;
    CGRect bounds = CGRectInset(layer.bounds, lineWidth, lineWidth);
    layer.path = [UIBezierPath bezierPathWithOvalInRect:bounds].CGPath;
    layer.fillColor = UIColor.clearColor.CGColor;
    layer.strokeColor = strokeColor.CGColor;
    layer.lineWidth = lineWidth;
    layer.lineCap = kCALineCapRound;
    layer.strokeStart = 0.08;
    layer.strokeEnd = 0.92;
    return layer;
}

static UIView *WaykinDarkDayArtwork(CGRect frame) {
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.backgroundColor = WaykinColor(0.018, 0.025, 0.075, 1.0);

    CAGradientLayer *sky = [CAGradientLayer layer];
    sky.frame = view.bounds;
    sky.colors = @[
        (__bridge id)WaykinColor(0.02, 0.025, 0.10, 1).CGColor,
        (__bridge id)WaykinColor(0.11, 0.06, 0.25, 1).CGColor,
        (__bridge id)WaykinColor(0.32, 0.10, 0.38, 1).CGColor
    ];
    sky.locations = @[@0.0, @0.62, @1.0];
    [view.layer addSublayer:sky];

    UIView *beam = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMidX(frame) - 1.0, frame.size.height * 0.19, 2.0, frame.size.height * 0.58)];
    beam.backgroundColor = WaykinColor(0.72, 0.48, 1.0, 0.88);
    beam.layer.shadowColor = WaykinColor(0.58, 0.32, 1.0, 1).CGColor;
    beam.layer.shadowOpacity = 1.0;
    beam.layer.shadowRadius = 12.0;
    [view addSubview:beam];

    for (NSInteger index = 0; index < 42; index++) {
        CGFloat x = ((index * 73) % 997) / 997.0 * frame.size.width;
        CGFloat y = ((index * 131) % 619) / 619.0 * frame.size.height * 0.62;
        CGFloat size = index % 5 == 0 ? 2.2 : 1.1;
        UIView *star = [[UIView alloc] initWithFrame:CGRectMake(x, y, size, size)];
        star.backgroundColor = WaykinColor(0.86, 0.78, 1.0, 0.82);
        star.layer.cornerRadius = size / 2.0;
        [view addSubview:star];
    }

    return view;
}

static UIView *WaykinLightNightArtwork(CGRect frame) {
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.backgroundColor = WaykinColor(0.965, 0.955, 0.925, 1.0);

    CAGradientLayer *wash = [CAGradientLayer layer];
    wash.frame = view.bounds;
    wash.colors = @[
        (__bridge id)WaykinColor(0.99, 0.98, 0.95, 1).CGColor,
        (__bridge id)WaykinColor(0.92, 0.95, 0.93, 1).CGColor,
        (__bridge id)WaykinColor(0.78, 0.86, 0.84, 1).CGColor
    ];
    wash.startPoint = CGPointMake(0.2, 0.0);
    wash.endPoint = CGPointMake(0.9, 1.0);
    [view.layer addSublayer:wash];

    for (NSInteger index = 0; index < 8; index++) {
        CGFloat scale = 1.0 - index * 0.08;
        CGFloat size = frame.size.width * 0.55 * scale;
        CAShapeLayer *contour = WaykinCircleLayer(
            CGRectMake(CGRectGetMidX(frame) - size / 2.0, frame.size.height * 0.12 + index * 9.0, size, size),
            WaykinColor(0.57, 0.51, 0.38, 0.16),
            0.7
        );
        [view.layer addSublayer:contour];
    }

    return view;
}

/// Prefer bundled Waykin Display for brand titles; system medium as fallback.
static UIFont *WaykinBrandFont(CGFloat size, UIFontWeight weight) {
    UIFont *display = [UIFont fontWithName:@"WaykinDisplay-Regular" size:size];
    if (display != nil) {
        return display;
    }
    return [UIFont systemFontOfSize:size weight:weight];
}

static UILabel *WaykinLabel(NSString *text, CGFloat size, UIFontWeight weight, UIColor *color) {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = text;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = color;
    label.font = WaykinBrandFont(size, weight);
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.75;
    return label;
}

static UIView *WaykinSplashContent(CGRect frame, BOOL darkArtwork) {
    UIView *root = darkArtwork ? WaykinDarkDayArtwork(frame) : WaykinLightNightArtwork(frame);
    UIColor *primary = darkArtwork ? UIColor.whiteColor : WaykinColor(0.10, 0.16, 0.18, 1.0);
    UIColor *accent = darkArtwork ? WaykinColor(0.72, 0.55, 1.0, 1.0) : WaykinColor(0.39, 0.34, 0.23, 1.0);

    CGFloat emblemSize = MIN(frame.size.width * 0.26, 122.0);
    CAShapeLayer *emblem = WaykinCircleLayer(
        CGRectMake(CGRectGetMidX(frame) - emblemSize / 2.0, frame.size.height * 0.19, emblemSize, emblemSize),
        accent,
        6.0
    );
    [root.layer addSublayer:emblem];

    UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMidX(frame) - 4.5, frame.size.height * 0.19 + emblemSize / 2.0 - 4.5, 9.0, 9.0)];
    dot.backgroundColor = accent;
    dot.layer.cornerRadius = 4.5;
    [root addSubview:dot];

    UILabel *title = WaykinLabel(@"W A Y K I N", 30.0, UIFontWeightMedium, primary);
    title.frame = CGRectMake(28.0, frame.size.height * 0.39, frame.size.width - 56.0, 48.0);
    [root addSubview:title];

    UILabel *tagline = WaykinLabel(@"WALK.  BOND.  BECOME.", 12.0, UIFontWeightRegular, accent);
    tagline.frame = CGRectMake(34.0, CGRectGetMaxY(title.frame) + 4.0, frame.size.width - 68.0, 26.0);
    [root addSubview:tagline];

    UILabel *companion = WaykinLabel(@"ᐱ", 74.0, UIFontWeightLight, accent);
    companion.transform = CGAffineTransformMakeRotation(M_PI);
    companion.frame = CGRectMake(CGRectGetMidX(frame) - 45.0, frame.size.height * 0.72, 90.0, 96.0);
    companion.alpha = darkArtwork ? 0.92 : 0.72;
    [root addSubview:companion];

    root.isAccessibilityElement = YES;
    root.accessibilityIdentifier = @"waykin.splash";
    root.accessibilityLabel = @"Waykin. Walk. Bond. Become.";
    return root;
}

static UIWindowScene *WaykinForegroundScene(void) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:UIWindowScene.class] && scene.activationState != UISceneActivationStateUnattached) {
            return (UIWindowScene *)scene;
        }
    }
    return nil;
}

static void WaykinPresentSplash(void) {
    if (WaykinIsUITesting() || WaykinSplashWindow != nil) {
        return;
    }

    UIWindowScene *scene = WaykinForegroundScene();
    if (scene == nil) {
        return;
    }

    UIWindow *window = [[UIWindow alloc] initWithWindowScene:scene];
    window.frame = scene.coordinateSpace.bounds;
    window.windowLevel = UIWindowLevelAlert + 1.0;
    window.backgroundColor = UIColor.clearColor;

    UIViewController *controller = [[UIViewController alloc] init];
    controller.view = WaykinSplashContent(window.bounds, WaykinUsesDarkDayArtwork([NSDate date]));
    window.rootViewController = controller;
    window.userInteractionEnabled = NO;
    window.accessibilityViewIsModal = NO;
    window.hidden = NO;
    WaykinSplashWindow = window;

    controller.view.alpha = 0.0;
    controller.view.transform = CGAffineTransformMakeScale(1.015, 1.015);
    [UIView animateWithDuration:0.28 animations:^{
        controller.view.alpha = 1.0;
        controller.view.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.62 delay:0.72 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            controller.view.alpha = 0.0;
            controller.view.transform = CGAffineTransformMakeScale(1.025, 1.025);
        } completion:^(BOOL finished) {
            WaykinSplashWindow.hidden = YES;
            WaykinSplashWindow.rootViewController = nil;
            WaykinSplashWindow = nil;
        }];
    }];
}

__attribute__((constructor))
static void WaykinInstallSplashBootstrap(void) {
    if (WaykinIsUITesting()) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        WaykinLaunchObserver = [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidBecomeActiveNotification
                                                                                 object:nil
                                                                                  queue:NSOperationQueue.mainQueue
                                                                             usingBlock:^(__unused NSNotification *notification) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                WaykinPresentSplash();
            });
        }];

        if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
            WaykinPresentSplash();
        }
    });
}
