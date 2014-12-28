//
//  VideoGLView.m
//  LiveVideo
//
//  Created by IKKO FUSHIKI on 12/18/14.
//  Copyright (c) 2014 IKKO FUSHIKI. All rights reserved.
//

#import "VideoGLView.h"
#import "MyImports.h"
#import "../../DWCommon/DwStaticLib/DwStaticLib/DwStaticLib_cpp.h"
#import "VideoGLRenderer.h"
//#import "TestGLRenderer.h"

@implementation VideoGLView

@synthesize imagePipe;
@synthesize useVideoTexture;

- (DwGLBaseRenderer *) createRenderer
{
//    return [[VideoGLRenderer alloc] init];

    return [[VideoGLRenderer alloc] initWithDefaultFBO:0 withView:self];
}

// This initialize only the input buffer in imagePipe.
- (void) initImagePipe:(NSRect) bounds
{
    self.imagePipe = [[DwImagePipe alloc] init];
    if (self.imagePipe) {
        [self.imagePipe initBufferParameters:bounds withFlag:ImageBufferFlag_Input];
    }
    
    self.useVideoTexture = NO;
}

//======================================================================================
// receiveImageData:
//
// Called from AvManager:captureOutput
//======================================================================================
- (void) receiveImageData:(void *) dataBuffer withBytesPerRow:(long) bytesPerRow1 withWidth:(long) width1 withHeight:(long) height1
{
    if (self.imagePipe) {
        [self.imagePipe receiveImageData:dataBuffer withBytesPerRow:bytesPerRow1 withWidth:width1 withHeight:height1];
    }
}

- (void) setTextureMode:(BOOL) videoMode
{
    VideoGLRenderer *videoRenderer = (VideoGLRenderer *) self.m_renderer;
    
    if (videoRenderer && self.useVideoTexture == YES && videoMode == NO) {
        [videoRenderer setToStaticTexture];
    }
    self.useVideoTexture = videoMode;
}

@end
