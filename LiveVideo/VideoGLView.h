//
//  VideoGLView.h
//  LiveVideo
//
//  Created by IKKO FUSHIKI on 12/18/14.
//  Copyright (c) 2014 IKKO FUSHIKI. All rights reserved.
//

#import "MyImports.h"
#import "../../DWCommon/DwStaticLib/DwStaticLib/AudioVisual/OpenGL/DwGLBaseView.h"

@interface VideoGLView : DwGLBaseView

@property BOOL useVideoTexture;

- (void) initImagePipe:(NSRect) bounds;
- (void) receiveImageData:(void *) dataBuffer withBytesPerRow:(long) bytesPerRow withWidth:(long) width withHeight:(long) height;
- (void) setTextureMode:(BOOL) videoMode;

@property (strong) DwImagePipe* imagePipe;

@end
