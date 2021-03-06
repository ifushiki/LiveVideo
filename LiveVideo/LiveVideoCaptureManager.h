//
//  DwVideoCaptureManager.h
//  AVVideoCapture
//
//  Created by IKKO FUSHIKI on 11/24/14.
//
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreVideo/CVPixelBuffer.h>
#import "MyImports.h"
#import "VideoGLView.h"
#import "VideoGLRenderer.h"

// When using CALayer for drawing filtered image, set USE_FILTER_LAYER to YES
#define USE_FILTER_LAYER  YES

@interface LiveVideoCaptureManager : NSObject <AVCaptureFileOutputDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (strong)  AVCaptureSession			*session;
@property (strong)  AVCaptureDeviceInput		*videoDeviceInput;
@property (strong)  AVCaptureDeviceInput		*audioDeviceInput;
@property (strong)  AVCaptureAudioPreviewOutput	*audioPreviewOutput;
@property (strong)  AVCaptureVideoDataOutput    *videoDataOutput;
@property (strong)  NSArray                     *videoDevices;
@property (strong)  NSArray                     *audioDevices;
@property (strong)  NSTimer                     *audioLevelTimer;
@property (strong)  NSArray						*observers;
@property (weak)    NSLevelIndicator            *audioLevelMeter;

@property (weak) AVCaptureDevice                *selectedVideoDevice;
@property (weak) AVCaptureDevice                *selectedAudioDevice;

@property (weak) NSView                         *videoOutputView;
@property (weak) DwVideoOutputView              *videoOutputView2;
@property (weak) DwVideoOutputLayer             *videoOutputLayer2;
@property (strong) VideoGLView                  *myGLView;

@property (assign) void*                        *dataBuffer;
@property (assign) long                         dataBufferSize;


- (void)refreshDevices;
- (void)setTransportMode:(AVCaptureDeviceTransportControlsPlaybackMode)playbackMode
                   speed:(AVCaptureDeviceTransportControlsSpeed)speed forDevice:(AVCaptureDevice *)device;
- (void) setOutputViews:(NSView *) outputView1 withSecondView:(DwVideoOutputView *) outputView2 withSecondLayer:(DwVideoOutputLayer *) outputLayer2 withGLView:(VideoGLView *) itsGLView;

@end
