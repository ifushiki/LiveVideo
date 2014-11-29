//
//  LiveVideoDocument.h
//  LiveVideo
//
//  Created by IKKO FUSHIKI on 11/27/14.
//  Copyright (c) 2014 IKKO FUSHIKI. All rights reserved.
//

#import "MyImports.h"

@class LiveVideoCaptureManager;

@interface LiveVideoDocument : DwDocument
{
/*
@private
    NSView						*__weak previewView;
    NSView                      *__weak videoOutputView;
    DwVideoOutputView             *__weak videoOutputView2;
    LiveVideoManager                   *avManager;
 */
}

#pragma mark - Preview
@property (weak) IBOutlet NSView *previewView;
@property (weak) IBOutlet NSView *videoOutputView;
@property (weak) IBOutlet DwVideoOutputView *videoOutputView2;
@property (strong) LiveVideoCaptureManager *avManager;
@property (strong) DwVideoOutputView* filterView;

@property (strong) IBOutlet NSSegmentedControl *filterChoice;
@property (strong) IBOutlet NSMatrix  *colorChoice;

- (IBAction) getFilter:(id)sender;
- (IBAction) getColorMode:(id)sender;
- (IBAction) togglePlayMode:(id) sender;

@end

