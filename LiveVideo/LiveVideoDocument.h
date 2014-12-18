//
//  LiveVideoDocument.h
//  LiveVideo
//
//  Created by IKKO FUSHIKI on 11/27/14.
//  Copyright (c) 2014 IKKO FUSHIKI. All rights reserved.
//

#import "MyImports.h"
@class LiveVideoCaptureManager;
@class DwGLBaseView;

@interface LiveVideoDocument : DwDocument

#pragma mark - Preview
@property (weak) IBOutlet NSView *previewView;
@property (weak) IBOutlet NSView *videoOutputView;
@property (weak) IBOutlet NSView *videoOutputView2;
@property (weak) IBOutlet NSView *glViewHolder;
@property (strong) DwGLBaseView *myGLView;

@property (strong) LiveVideoCaptureManager *avManager;
@property (strong) DwVideoOutputView* filterView;
@property (strong) DwVideoOutputLayer* filterLayer;

@property (strong) IBOutlet NSSegmentedControl *filterChoice;
@property (strong) IBOutlet NSMatrix  *colorChoice;

@property CVDisplayLinkRef displayLink;

- (IBAction) getFilter:(id)sender;
- (IBAction) getColorMode:(id)sender;
- (IBAction) togglePlayMode:(id) sender;

@end

