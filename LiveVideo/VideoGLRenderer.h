//
//  VideoGLRenderer.h
//  LiveVideo
//
//  Created by IKKO FUSHIKI on 12/18/14.
//  Copyright (c) 2014 IKKO FUSHIKI. All rights reserved.
//

#import "../../DWCommon/DwStaticLib/DwStaticLib/AudioVisual/OpenGL/DwGLBaseRenderer.h"

@interface VideoGLRenderer : DwGLBaseRenderer
{
    GLuint m_defaultFBOName;

}

- (id) initWithDefaultFBO: (GLuint) defaultFBOName;

@end
