//
//  LiveVideoDocument.m
//  LiveVideo
//
//  Created by IKKO FUSHIKI on 11/27/14.
//  Copyright (c) 2014 IKKO FUSHIKI. All rights reserved.
//

#import "LiveVideoDocument.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreVideo/CVPixelBuffer.h>
#import "LiveVideoCaptureManager.h"
#import "../../DWCommon/DwStaticLib/DwStaticLib/DwStaticLib.h"
#import "../../DWCommon/DwStaticLib/DwStaticLib/DwStaticLib_cpp.h"
#import "VideoGLView.h"
#import "VideoGLRenderer.h"

@interface LiveVideoDocument ()
{
    // A handle for dynamic library.
    void* lib_handle;
    BOOL displayLinkStarted;
}

// Properties for internal use
@property (strong) AVCaptureVideoPreviewLayer   *previewLayer;
@property (strong) CAShapeLayer                 *shapeLayer;
@property (strong) CAShapeLayer                 *starLayer;

@property (weak) NSTimer *animationTimer;
@property long  animationCount;

- (void) moveSprites:(id) sender;

@end

@implementation LiveVideoDocument

@synthesize previewView, videoOutputView, videoOutputView2;
@synthesize myGLView;

@synthesize filterView;
@synthesize avManager;
@synthesize filterChoice, colorChoice;

@synthesize previewLayer;
@synthesize shapeLayer;
@synthesize starLayer;

@synthesize animationTimer;
@synthesize animationCount;
@synthesize displayLink;

CAShapeLayer* createRectLayer(CGRect frame, CGColorRef color);
CAShapeLayer* createStarLayer(CGRect frame, CGColorRef color);

CAShapeLayer* createRectLayer(CGRect frame, CGColorRef color)
{
    CAShapeLayer *newLayer = [CAShapeLayer layer];
    CGPathRef cgPath = CGPathCreateWithRect(CGRectMake(0, 0, frame.size.width, frame.size.height), NULL);
    newLayer.frame = frame;
    newLayer.path = cgPath;
    newLayer.lineWidth = 3.0;
    newLayer.strokeColor = color;
    newLayer.fillColor = [NSColor clearColor].CGColor;
    
    return newLayer;
}

CAShapeLayer* createStarLayer(CGRect frame, CGColorRef color)
{
    CAShapeLayer *newLayer = [CAShapeLayer layer];
    CGMutablePathRef cgPath = CGPathCreateMutable();
    float halfW = frame.size.width/2;
    float halfH = frame.size.height/2;
    CGPoint center = CGPointMake(halfW, halfH);
    CGPoint pts[10];
    float scale[2];
    scale[0] = 0.98; // Shrink a little so that the thick lines do not go out of bounds.
    scale[1] = 0.5;
    
    float dTheta = M_PI/5;
    float theta = M_PI/2;
    
    for (int i = 0; i < 10; i++) {
        int mode = i % 2;
        pts[i].x = center.x + scale[mode]*halfW*cos(theta);
        pts[i].y = center.y + scale[mode]*halfH*sin(theta);
        theta += dTheta;
    }
    
    CGPathAddLines(cgPath, nil, pts, 10);
    CGPathCloseSubpath(cgPath);
    
    newLayer.frame = frame;
    newLayer.path = cgPath;
    newLayer.lineWidth = 3.0;
    newLayer.strokeColor = color;
    newLayer.fillColor = [NSColor clearColor].CGColor;
    
    return newLayer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
//        [self openDwDynamicLib];
//        [self testLibraries];

        animationCount = 0;
        
        // Set up LiveVideoCaptureManager.
        avManager = [[LiveVideoCaptureManager alloc] init];
        displayLinkStarted = NO;
    }
    return self;
}

- (void)windowWillClose:(NSNotification *)notification
{
    // Invalidate animation timer.
    [[self animationTimer] invalidate];
    
    // Invalidate the level meter timer here to avoid a retain cycle
    [[avManager audioLevelTimer] invalidate];
    
    // Stop the session
    [[avManager session] stopRunning];

    // Stop the displayLink.
//    CVDisplayLinkStop(self.displayLink);
    
    if (self.myGLView)
        CVDisplayLinkStop(self.myGLView.displayLink);
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.

    // Attach a main layer to the previewView.
    CALayer *mainLayer = [[self previewView] layer];
    if (mainLayer == nil) {
        mainLayer = [CALayer layer];
        [self.previewView setWantsLayer:YES];   // This is very important to set this flag to be true!!!
        [self.previewView setLayer:mainLayer];
    }
    [mainLayer setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];
    
    // Create a video preview layer and add it to the main layer.
    AVCaptureVideoPreviewLayer *newPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:[avManager session]];
    [newPreviewLayer setFrame:[mainLayer bounds]];
    [newPreviewLayer setAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable];
    [mainLayer addSublayer:newPreviewLayer];

    // Set the previewLayer instance to the above created video preview layer.
    self.previewLayer = newPreviewLayer;
    
    // Add a rectangle layer.
    CGRect frame = CGRectMake(200, 100, 50, 50);
    shapeLayer = createRectLayer(frame, [NSColor redColor].CGColor);
    [newPreviewLayer addSublayer:shapeLayer];
    
    // Add a star layer.
    frame.origin = CGPointMake(300, 200);
    starLayer = createStarLayer(frame, [NSColor yellowColor].CGColor);
    [newPreviewLayer addSublayer:starLayer];
    
    // Add a CALayer to videoOutputView.
    CALayer *videoOutputViewLayer = [self.videoOutputView layer];
    if (videoOutputViewLayer == nil) {
        videoOutputViewLayer = [CALayer layer];
        [self.videoOutputView setWantsLayer:YES];   // This is very important to set this flag to be true!!!
        [self.videoOutputView setLayer:videoOutputViewLayer];
    }
    if (videoOutputViewLayer) {
        [videoOutputViewLayer setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];
        videoOutputViewLayer.frame = self.videoOutputView.bounds;
    }
    
    // Add a DwVideoOutputLayer if we use the layer for drawing in videoOutputView2.
    CGRect bounds2 = CGRectMake(0, 0, 360, 240);
    if (self.videoOutputView2 != nil) {
        bounds2 = self.videoOutputView2.bounds;
        if(USE_FILTER_LAYER) {
            self.filterView = nil;
            self.filterLayer = [[DwVideoOutputLayer alloc] initWithFrame:bounds2];
            [self.videoOutputView2 setWantsLayer:YES];
            [self.videoOutputView2 setLayer:self.filterLayer];
        }
        else {
            self.filterLayer = nil;
            self.filterView = [[DwVideoOutputView alloc] initWithFrame:bounds2];
            [self.videoOutputView2 addSubview:self.filterView];
        }
    }
    
    if (self.glViewHolder) {
        NSRect bounds = self.glViewHolder.bounds;
        // Use the arent's view's bounds so that the frame origin is 0.
//        self.myGLView = [[SimpleGLView alloc] init];
//        self.myGLView = [[DwOpenGLView alloc] init];
        self.myGLView = [[VideoGLView alloc] init];
        self.myGLView.frame = bounds;   // The frame origin is 0.
        [self.myGLView initPixelFormatAndContext];
        
        // Initialize image pipe.  The dimension of the receiving image is the same as videoOutputView2
        [self.myGLView initImagePipe:bounds2];
        
        // myGLView's prepareOpenGL method will be called when its parent's view is set.
        [self.glViewHolder addSubview:self.myGLView];
    }
    
    CVReturn            error = kCVReturnSuccess;
    CGDirectDisplayID   displayID = CGMainDisplayID();// 1
    
    error = CVDisplayLinkCreateWithCGDisplay(displayID, &displayLink);// 2
    if(error)
    {
        NSLog(@"DisplayLink created with error:%d", error);
        displayLink = NULL;
        return;
    }
    
    error = CVDisplayLinkSetOutputCallback(displayLink,// 3
                                           MyDisplayLinkCallback, (__bridge void *) self);

    [avManager setOutputViews:videoOutputView withSecondView:self.filterView withSecondLayer:self.filterLayer
        withGLView:self.myGLView];
    
    // Start the session
    [[avManager session] startRunning];

    // Start the animation timer.
    [self setAnimationTimer:[NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(moveSprites:) userInfo:nil repeats:YES]];
    
    // Activate the display link
//    CVDisplayLinkStart(self.displayLink);
}

// This is the renderer output callback function
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink,
                                      const CVTimeStamp* now,
                                      const CVTimeStamp* outputTime,
                                      CVOptionFlags flagsIn,
                                      CVOptionFlags* flagsOut,
                                      void* displayLinkContext)
{
    CVReturn    result = kCVReturnSuccess;
    LiveVideoDocument* myDocument = (__bridge LiveVideoDocument* ) displayLinkContext;
    
    if(USE_FILTER_LAYER) {
        DwVideoOutputLayer* layer = myDocument.filterLayer;
        if (layer && [layer.imagePipe isReadyToReceiveNewData] == NO)
        {
            // setNeedsDisplay must be called in the main thread.
            [layer performSelectorOnMainThread:@selector(updateLayer:) withObject:nil waitUntilDone:YES];
        }
    }
    else {
        DwVideoOutputView* view = myDocument.filterView;
        
        // Call a display update only when the new data is already received and ready to draw (when isReadyToReceiveNewData() is false).
        if (view && [view.imagePipe isReadyToReceiveNewData]  == NO)
        {
            [view setNeedsDisplay:YES];
        }
    }
    return result;
}

+ (BOOL)autosavesInPlace {
    return YES;
}

- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"LiveVideoDocument";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    [NSException raise:@"UnimplementedMethod" format:@"%@ is unimplemented", NSStringFromSelector(_cmd)];
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    [NSException raise:@"UnimplementedMethod" format:@"%@ is unimplemented", NSStringFromSelector(_cmd)];
    return YES;
}

- (void) moveSprites: (id) sender
{
    CATransform3D shapeTransform = CATransform3DIdentity;
    float angle = 10*animationCount * M_PI/180;
    CATransform3D rotation = CATransform3DRotate(shapeTransform, angle, 0.0, 0.0, 1.0);
    CATransform3D elevate = CATransform3DMakeTranslation(0, 0, 200);
    float tx = 100*cos(angle);
    float ty = 50*sin(2*angle);
    CATransform3D trans = CATransform3DMakeTranslation(tx, ty, 0);
    CATransform3D newTrans = CATransform3DConcat(rotation, elevate);
    newTrans = CATransform3DConcat(trans, newTrans);
    shapeLayer.transform = newTrans;
    
    shapeTransform = CATransform3DIdentity;
    rotation = CATransform3DRotate(shapeTransform, 2*angle, 0, 0, 1.0);
    elevate = CATransform3DMakeTranslation(0, 0, 300);
    float r = 100*cos(3*angle);
    tx = r*cos(2*angle);
    ty = r*sin(2*angle);
    trans = CATransform3DMakeTranslation(tx, ty, 0);
    newTrans = CATransform3DConcat(rotation, elevate);
    newTrans = CATransform3DConcat(trans, newTrans);
    starLayer.transform = newTrans;
    
    // Add a perspetvive transform to videoOutputView layer.
    CALayer *layer = [self.videoOutputView layer];
    shapeTransform = CATransform3DIdentity;
    float eyePosition = 400;
    shapeTransform.m34 = -1.0/eyePosition;
    rotation = CATransform3DRotate(shapeTransform, angle, 0.0, 1.0, 0.2);
    elevate = CATransform3DMakeTranslation(0, 0, 0);
    newTrans = CATransform3DConcat(rotation, elevate);
    layer.transform = newTrans;
    
//    self.filterLayer.transform = newTrans;
    
    animationCount++;
    if (animationCount > 36) {
        animationCount -= 36;
    }
    
    // Add a delayed start for SVDsiplayLink.
    if (displayLinkStarted == NO) {
        CVDisplayLinkStart(self.displayLink);
        displayLinkStarted = YES;
    }
}

- (IBAction) setFilter:(id)sender
{
    // Get the filter selection
    int index = (int) [sender selectedSegment];

    DwImagePipe* imagePipe = nil;
    if (USE_FILTER_LAYER) {
        if (self.filterLayer) {
            imagePipe = self.filterLayer.imagePipe;
        }
    }
    else {
        if (self.filterView) {
            imagePipe = self.filterView.imagePipe;
        }
    }
    
    if (imagePipe) {
        [imagePipe changeFilter:index];
    }
}

- (IBAction) setColorMode:(id)sender
{
    // Get the filter selection
    NSButtonCell *cell = [sender selectedCell];
    NSString* title = cell.title;
    DwImagePipe* imagePipe = nil;
    if (USE_FILTER_LAYER) {
        if (self.filterLayer) {
            imagePipe = self.filterLayer.imagePipe;
        }
    }
    else {
        if (self.filterView) {
            imagePipe = self.filterView.imagePipe;
        }
    }
    
    if (imagePipe == nil)
        return;
    
    if ([title isEqualToString:@"Color"]) {
        [imagePipe changeColorMode:kColor];
    }
    else if ([title isEqualToString:@"Gray"]) {
        [imagePipe changeColorMode:kGray];
    }
}

- (IBAction) togglePlayMode:(id) sender;
{
    BOOL playing = NO;
    
    DwImagePipe *imagePipe = nil;
    if (USE_FILTER_LAYER) {
        if (self.filterLayer) {
            imagePipe = self.filterLayer.imagePipe;
        }
    }
    else {
        if (self.filterView) {
            imagePipe = self.filterView.imagePipe;
        }
    }
    
    if (imagePipe) {
        playing = [imagePipe isPlaying];
    }

    if (playing) {
        // Change the image to play button
        [sender setImage:[NSImage imageNamed:@"play-button.png"]];
        [[avManager session] stopRunning];
    }
    else {
        // Change the image to stop button
        [sender setImage:[NSImage imageNamed:@"pause-button.png"]];
        [[avManager session] startRunning];
    }
    
    if (imagePipe) {
        [imagePipe togglePlayMode];
    }
}

- (IBAction) setTextureMode:(id) sender;
{
    // Get the filter selection
    NSButtonCell *cell = [sender selectedCell];
    NSString* title = cell.title;
    BOOL videoMode = NO;
    
    if (self.myGLView) {
        if ([title isEqualToString:@"Static"]) {
            videoMode = NO;
        }
        else if ([title isEqualToString:@"Video"]) {
            videoMode = YES;
        }
        
        [self.myGLView setTextureMode:videoMode];
    }    
}

@end
