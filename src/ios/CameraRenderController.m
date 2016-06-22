#import "CameraRenderController.h"
#import <CoreVideo/CVOpenGLESTextureCache.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/glext.h>

@implementation CameraRenderController
@synthesize context = _context;
@synthesize delegate;



- (CameraRenderController *)init {
    if (self = [super init]) {
        self.renderLock = [[NSLock alloc] init];
    }
    return self;
}

- (void)loadView {
    GLKView *glkView = [[GLKView alloc] init];
    [glkView setBackgroundColor:[UIColor blackColor]];
    [self setView:glkView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.context, NULL, &_videoTextureCache);
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
        return;
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.contentMode = UIViewContentModeScaleToFill;
    
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    self.ciContext = [CIContext contextWithEAGLContext:self.context];
    
    if (self.dragEnabled) {
        //add drag action listener
        NSLog(@"Enabling view dragging");
        UIPanGestureRecognizer *drag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self.view addGestureRecognizer:drag];
    }
    
    if (self.tapToTakePicture) {
        //tap to take picture
        UITapGestureRecognizer *takePictureTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTakePictureTap:)];
        [self.view addGestureRecognizer:takePictureTap];
    }
    
    self.view.userInteractionEnabled = self.dragEnabled || self.tapToTakePicture;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appplicationIsActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationEnteredForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    dispatch_async(self.sessionManager.sessionQueue, ^{
        NSLog(@"Starting session");
        [self.sessionManager.session startRunning];
    });
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
    
    dispatch_async(self.sessionManager.sessionQueue, ^{
        NSLog(@"Stopping session");
        [self.sessionManager.session stopRunning];
    });
}

- (void) handleTakePictureTap:(UITapGestureRecognizer*)recognizer {
    NSLog(@"handleTakePictureTap");
    [self.delegate invokeTakePicture];
}

- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.view];
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                         recognizer.view.center.y + translation.y);
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
}

- (void) appplicationIsActive:(NSNotification *)notification {
    dispatch_async(self.sessionManager.sessionQueue, ^{
        NSLog(@"Starting session");
        [self.sessionManager.session startRunning];
    });
}

- (void) applicationEnteredForeground:(NSNotification *)notification {
    dispatch_async(self.sessionManager.sessionQueue, ^{
        NSLog(@"Stopping session");
        [self.sessionManager.session stopRunning];
    });
}
//TODO:Use TEXTURE_2D
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if ([self.renderLock tryLock]) {
        
        CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        
        CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        CIFilter *filter = [self.sessionManager ciFilter];
        
        [self.sessionManager.filterLock lock];
        
        //Clamp filter
        CIFilter *clampFilter = [CIFilter filterWithName:@"CIAffineClamp"];
        [clampFilter setDefaults];
        [clampFilter setValue:image forKey:kCIInputImageKey];
        
        //Blur filter
        [filter setValue:clampFilter.outputImage forKey:kCIInputImageKey];
        
        CIImage *result = [filter outputImage];
        
        [self.sessionManager.filterLock unlock];
        
        self.latestFrame = result;
        
        CGFloat pointScale;
        if ([[UIScreen mainScreen] respondsToSelector:@selector(nativeScale)]) {
            pointScale = [[UIScreen mainScreen] nativeScale];
        } else {
            pointScale = [[UIScreen mainScreen] scale];
        }
        CGRect dest = CGRectMake(0, 0, self.view.frame.size.width*pointScale, self.view.frame.size.height*pointScale);
        
        [self.ciContext drawImage:result inRect:dest fromRect:[image extent]];
        [self.context presentRenderbuffer:GL_RENDERBUFFER];
        [(GLKView *)(self.view)display];
        [self.renderLock unlock];
        
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc. that aren't in use.
}

- (BOOL)shouldAutorotate {
    return YES;
}
-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.sessionManager updateOrientation:[self.sessionManager getCurrentOrientation:toInterfaceOrientation]];
}
@end
