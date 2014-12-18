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
#import "TestGLRenderer.h"

@implementation VideoGLView

- (DwGLBaseRenderer *) createRenderer
{
//    return [[VideoGLRenderer alloc] init];

    return [[TestGLRenderer alloc] initWithDefaultFBO:0];
}

@end
