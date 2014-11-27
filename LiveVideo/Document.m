//
//  Document.m
//  LiveVideo
//
//  Created by IKKO FUSHIKI on 11/27/14.
//  Copyright (c) 2014 IKKO FUSHIKI. All rights reserved.
//

#import "Document.h"
#import <objc/runtime.h>
#import <dlfcn.h>
#import "../../DWCommon/DwDynamicLib/DwDynamicLib/DwDynamicLib.h"
#import "../../DWCommon/DwStaticLib/DwStaticLib/DwStaticLib.h"

@interface Document ()
{
    void* lib_handle;
}

@end

@implementation Document

- (instancetype)init {
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
        [self openDwDynamicLib];
        [self testLibraries];
    }
    return self;
}

- (void) openDwDynamicLib
{
    // Add your subclass-specific initialization here.
    // Open the library.
    lib_handle = dlopen("./libDwDynamicLib.dylib", RTLD_LOCAL);
    if (!lib_handle) {
        NSLog(@"[%s] main: Unable to open library: %s\n",
              __FILE__, dlerror());
        exit(EXIT_FAILURE);
    }
}

- (void) closeDwDynamicLib
{
    // Close the library.
    if (dlclose(lib_handle) != 0) {
        NSLog(@"[%s] Unable to close library: %s\n",
              __FILE__, dlerror());
        exit(EXIT_FAILURE);
    }
}

- (void) testLibraries
{
    // Get the HelloDynLib class (required with runtime-loaded libraries).
    Class HelloDynamicLib_class = objc_getClass("HelloDynamicLib");
    if (!HelloDynamicLib_class) {
        NSLog(@"[%s] main: Unable to get HelloDynamicLib class", __FILE__);
        exit(EXIT_FAILURE);
    }
    
    // Create an instance of HelloDynLib.
    NSLog(@"[%s] main: Instantiating HelloDynamicLib_class", __FILE__);
    NSObject<HelloDynamicLib>* helloDynamicLib = [HelloDynamicLib_class new];
    // Use person.
    [helloDynamicLib setMessage:@"Hello Dynamic Library"];
    NSLog(@"[%s] main: [helloDynamicLib message] = %@", __FILE__, [helloDynamicLib message]);
    
    HelloStaticLib *helloStaticLib = [[HelloStaticLib alloc] init];
    if (!helloStaticLib)
    {
        NSLog(@"[%s] main: Unable to create HelloStaticLib class", __FILE__);
        exit(EXIT_FAILURE);
    }
    [helloStaticLib setMessage:@"Hello Static Library"];
    NSLog(@"[%s] main: [helloStaticLib message] = %@", __FILE__, [helloStaticLib message]);
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

+ (BOOL)autosavesInPlace {
    return YES;
}

- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"Document";
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

@end
