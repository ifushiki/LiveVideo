//
//  LiveVideoCaptureManager.m
//  AVVideoCapture
//
//  Created by IKKO FUSHIKI on 11/24/14.
//
//

#import "LiveVideoCaptureManager.h"

@implementation LiveVideoCaptureManager

@synthesize session, videoDeviceInput;
@synthesize audioDeviceInput, audioPreviewOutput, videoDataOutput;
@synthesize videoDevices, audioDevices,audioLevelTimer;
@synthesize observers;
@synthesize videoOutputView, videoOutputView2, videoOutputLayer2;
@synthesize dataBuffer, dataBufferSize;

- (id) init
{
    if (self = [super init] )
    {
        // Create a capture session
        self.session = [[AVCaptureSession alloc] init];
        
        // Attach outputs to session
        self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
        AVCaptureConnection *conn = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        [conn setVideoMinFrameDuration:CMTimeMake(1, 10)];
        [conn setVideoMaxFrameDuration:CMTimeMake(1, 2)];
        
        dispatch_queue_t queue;
        queue = dispatch_queue_create("cameraQueue", NULL);
        [self.videoDataOutput setSampleBufferDelegate:self queue:queue];
//        dispatch_release(queue);
        //        float width = 640;
        //        float height = 480;
        float width = 320;
        float height = 240;
        
        NSDictionary *pixelBufferOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithDouble:width], (id)kCVPixelBufferWidthKey,
                                            [NSNumber numberWithDouble:height], (id)kCVPixelBufferHeightKey,
                                            [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey,
                                            nil];
        //        NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
        //        NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
        //        NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
        [self.videoDataOutput setVideoSettings:pixelBufferOptions];
        [self.session addOutput:self.videoDataOutput];
        
        
        self.audioPreviewOutput = [[AVCaptureAudioPreviewOutput alloc] init];
        [self.audioPreviewOutput setVolume:0.f];
        [self.session addOutput:self.audioPreviewOutput];
        
        // Select devices if any exist
        AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if (videoDevice) {
            [self setSelectedVideoDevice:videoDevice];
            [self setSelectedAudioDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio]];
        } else {
            [self setSelectedVideoDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeMuxed]];
        }
        
        // Initial refresh of device list
        [self refreshDevices];
        
        self.dataBufferSize = 640*4*480;
        self.dataBuffer = malloc(dataBufferSize);
        
        self.videoOutputView2 = nil;
        self.videoOutputLayer2 = nil;
    }
    return self;
}


- (void)dealloc
{
    // Remove Observers
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    for (id observer in [self observers])
        [notificationCenter removeObserver:observer];
    
    free(dataBuffer);
    
}

- (void) setOutputViews:(NSView *) outputView1 withSecondView:(DwVideoOutputView *) outputView2 withSecondLayer:(DwVideoOutputLayer *)outputLayer2
{
    self.videoOutputView = outputView1;
    self.videoOutputView2 = outputView2;
    self.videoOutputLayer2 = outputLayer2;
}

#pragma mark - Device selection
- (void)refreshDevices
{
    self.videoDevices = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] arrayByAddingObjectsFromArray:[AVCaptureDevice devicesWithMediaType:AVMediaTypeMuxed]];
    self.audioDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    
    [self.session beginConfiguration];
    
    if (![self.videoDevices containsObject:self.selectedVideoDevice])
        self.selectedVideoDevice = nil;
    
    if (![self.audioDevices containsObject:self.selectedAudioDevice])
        self.selectedAudioDevice = nil;
    
    [self.session commitConfiguration];
}

- (AVCaptureDevice *)selectedVideoDevice
{
    return [videoDeviceInput device];
}

- (void)setSelectedVideoDevice:(AVCaptureDevice *)selectedVideoDevice
{
    [[self session] beginConfiguration];
    
    if ([self videoDeviceInput]) {
        // Remove the old device input from the session
        [session removeInput:[self videoDeviceInput]];
        [self setVideoDeviceInput:nil];
    }
    
    if (selectedVideoDevice) {
        NSError *error = nil;
        
        // Create a device input for the device and add it to the session
        AVCaptureDeviceInput *newVideoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:selectedVideoDevice error:&error];
        if (newVideoDeviceInput == nil) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                //                [self presentError:error];
            });
        } else {
            if (![selectedVideoDevice supportsAVCaptureSessionPreset:[session sessionPreset]])
                [[self session] setSessionPreset:AVCaptureSessionPresetHigh];
            
            [[self session] addInput:newVideoDeviceInput];
            [self setVideoDeviceInput:newVideoDeviceInput];
        }
    }
    
    // If this video device also provides audio, don't use another audio device
    if ([self selectedVideoDeviceProvidesAudio])
        [self setSelectedAudioDevice:nil];
    
    [[self session] commitConfiguration];
}

- (AVCaptureDevice *)selectedAudioDevice
{
    return [audioDeviceInput device];
}

- (void)setSelectedAudioDevice:(AVCaptureDevice *)selectedAudioDevice
{
    [[self session] beginConfiguration];
    
    if ([self audioDeviceInput]) {
        // Remove the old device input from the session
        [session removeInput:[self audioDeviceInput]];
        [self setAudioDeviceInput:nil];
    }
    
    if (selectedAudioDevice && ![self selectedVideoDeviceProvidesAudio]) {
        NSError *error = nil;
        
        // Create a device input for the device and add it to the session
        AVCaptureDeviceInput *newAudioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:selectedAudioDevice error:&error];
        if (newAudioDeviceInput == nil) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                //                [self presentError:error];
            });
        } else {
            if (![selectedAudioDevice supportsAVCaptureSessionPreset:[session sessionPreset]])
                [[self session] setSessionPreset:AVCaptureSessionPresetHigh];
            
            [[self session] addInput:newAudioDeviceInput];
            [self setAudioDeviceInput:newAudioDeviceInput];
        }
    }
    
    [[self session] commitConfiguration];
}

#pragma mark - Device Properties

+ (NSSet *)keyPathsForValuesAffectingSelectedVideoDeviceProvidesAudio
{
    return [NSSet setWithObjects:@"selectedVideoDevice", nil];
}

- (BOOL)selectedVideoDeviceProvidesAudio
{
    return ([[self selectedVideoDevice] hasMediaType:AVMediaTypeMuxed] || [[self selectedVideoDevice] hasMediaType:AVMediaTypeAudio]);
}

+ (NSSet *)keyPathsForValuesAffectingVideoDeviceFormat
{
    return [NSSet setWithObjects:@"selectedVideoDevice.activeFormat", nil];
}

- (AVCaptureDeviceFormat *)videoDeviceFormat
{
    return [[self selectedVideoDevice] activeFormat];
}

- (void)setVideoDeviceFormat:(AVCaptureDeviceFormat *)deviceFormat
{
    NSError *error = nil;
    AVCaptureDevice *videoDevice = [self selectedVideoDevice];
    if ([videoDevice lockForConfiguration:&error]) {
        [videoDevice setActiveFormat:deviceFormat];
        [videoDevice unlockForConfiguration];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            //            [self presentError:error];
        });
    }
}

+ (NSSet *)keyPathsForValuesAffectingAudioDeviceFormat
{
    return [NSSet setWithObjects:@"selectedAudioDevice.activeFormat", nil];
}

- (AVCaptureDeviceFormat *)audioDeviceFormat
{
    return [[self selectedAudioDevice] activeFormat];
}

- (void)setAudioDeviceFormat:(AVCaptureDeviceFormat *)deviceFormat
{
    NSError *error = nil;
    AVCaptureDevice *audioDevice = [self selectedAudioDevice];
    if ([audioDevice lockForConfiguration:&error]) {
        [audioDevice setActiveFormat:deviceFormat];
        [audioDevice unlockForConfiguration];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            //            [self presentError:error];
        });
    }
}

#pragma mark - Transport Controls

- (void)setTransportMode:(AVCaptureDeviceTransportControlsPlaybackMode)playbackMode speed:(AVCaptureDeviceTransportControlsSpeed)speed forDevice:(AVCaptureDevice *)device
{
    NSError *error = nil;
    if ([device transportControlsSupported]) {
        if ([device lockForConfiguration:&error]) {
            [device setTransportControlsPlaybackMode:playbackMode speed:speed];
            [device unlockForConfiguration];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                //                [self presentError:error];
            });
        }
    }
}

#pragma mark - Delegate methods

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    /*We create an autorelease pool because as we are not in the main_queue our code is
     not executed in the main thread. So we have to create an autorelease pool for the thread we are in*/
    
    @autoreleasepool {
        
        // CVImageBufferRef and CVPixelBufferRef are identical (defined as typedef).
        //        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        /*Lock the image buffer*/
        CVPixelBufferLockBaseAddress(imageBuffer,0);
        /*Get information about the image*/
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        size_t length2 = bytesPerRow*height;
        
        size_t length = dataBufferSize <= length2 ? dataBufferSize: length2;
        
        //    if (width == 640 && height == 480) {
        
        memcpy(dataBuffer, baseAddress, length);
        
        uint8_t *linePtr = baseAddress;
        for (int i = 0; i < height; i++) {
            if (i > height/8 && i < height/4) {
                uint32_t *colPtr = (uint32_t *) linePtr;
                long j = height/8;
                colPtr += j;
                while (j < height/4) {
                    *colPtr++ = 0xff0000ff; // ARGB
                    j++;
                }
            }
            
            linePtr += bytesPerRow;
        }
        
        /*Create a CGImageRef from the CVImageBufferRef*/
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGImageRef newImage = CGBitmapContextCreateImage(newContext);
        
        /*We release some components*/
        CGContextRelease(newContext);
        CGColorSpaceRelease(colorSpace);
        
        /*We display the result on the custom layer. All the display stuff must be done in the main thread because
         UIKit is no thread safe, and as we are not in the main thread (remember we didn't use the main_queue)
         we use performSelectorOnMainThread to call our CALayer and tell it to display the CGImage.*/
        CALayer *outputViewLayer = [[self videoOutputView] layer];
        //    [self.customLayer performSelectorOnMainThread:@selector(setContents:) withObject: (id) newImage waitUntilDone:YES];
        [outputViewLayer performSelectorOnMainThread:@selector(setContents:) withObject: (__bridge id) newImage waitUntilDone:YES];
        
        if(USE_FILTER_LAYER)
        {
            if (self.videoOutputLayer2 && [self.videoOutputLayer2.imagePipe isReadyToReceiveNewData] == YES)
                [(DwVideoOutputLayer *) self.videoOutputLayer2 receiveImageData:dataBuffer withBytesPerRow:bytesPerRow withWidth:width withHeight:height];

        }
        else  {
            if (self.videoOutputView2 && [self.videoOutputView2.imagePipe isReadyToReceiveNewData] == YES)
                [(DwVideoOutputView *) self.videoOutputView2 receiveImageData:dataBuffer withBytesPerRow:bytesPerRow withWidth:width withHeight:height];
        }
        
        
        /*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly).
         Same thing as for the CALayer we are not in the main thread so ...*/
        //    NSImage *image= [NSImage imageWithCGImage:newImage scale:1.0 orientation:NSImageOrientationRight];
        
        /*We relase the CGImageRef*/
        CGImageRelease(newImage);
        //    }
        
        /*We unlock the  image buffer*/
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        
    }
}

- (BOOL)captureOutputShouldProvideSampleAccurateRecordingStart:(AVCaptureOutput *)captureOutput NS_AVAILABLE(10_8, NA)
{
    return NO;
}

@end
