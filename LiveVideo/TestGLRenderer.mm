//
//  TestGLRenderer.m
//  LiveVideo
//
//  Created by IKKO FUSHIKI on 12/18/14.
//  Copyright (c) 2014 IKKO FUSHIKI. All rights reserved.
//

#import "TestGLRenderer.h"
#import "../../DWCommon/DwStaticLib/DwStaticLib/DwStaticLib_cpp.h"

// Toggle this to disable vertex buffer objects
// (i.e. use client-side vertex array objects)
// This must be 1 if using the GL3 Core Profile on the Mac
#define USE_VERTEX_BUFFER_OBJECTS 1

// Toggle this to disable the rendering the reflection
// and setup of the GLSL progam, model and FBO used for
// the reflection.
#define RENDER_REFLECTION 1

@implementation TestGLRenderer

#if RENDER_REFLECTION
DwVertexArray m_reflectVertexArray;
GLuint m_reflectPrgName;
GLuint m_reflectTexName;

DwFrameBuffer m_reflectFrameBuffer;
GLuint m_reflectWidth;
GLuint m_reflectHeight;
GLint  m_reflectModelViewUniformIdx;
GLint  m_reflectProjectionUniformIdx;
GLint m_reflectNormalMatrixUniformIdx;
#endif // RENDER_REFLECTION


DwVertexArray m_characterVertexArray;
GLuint m_characterPrgName;
GLuint m_characterTexName;

GLint m_characterMvpUniformIdx;
GLfloat m_characterAngle;

//GLboolean m_useVBOs;

- (void) renderCharacter:(GLfloat *) mvp cullFace:(GLuint) cullDirection
{
    // Set the directiom of cull face.
    glCullFace(cullDirection);
    
    // Use the program that we previously created
    glUseProgram(m_characterPrgName);
    
    // Set the modelview projection matrix that we calculated above
    // in our vertex shader
    glUniformMatrix4fv(m_characterMvpUniformIdx, 1, GL_FALSE, mvp);
    
    // Bind the texture to be used
    glBindTexture(GL_TEXTURE_2D, m_characterTexName);
    
    DwDrawVertexArray(&m_characterVertexArray);
}

- (void) render
{
    // Set up the modelview and projection matricies
    GLfloat modelView[16];
    GLfloat projection[16];
    GLfloat mvp[16];
    
#if RENDER_REFLECTION
    
    // Bind our refletion FBO and render our scene
    
    glBindFramebuffer(GL_FRAMEBUFFER, m_reflectFrameBuffer.getFrameBuffer());
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glViewport(0, 0, m_reflectWidth, m_reflectHeight);
    
    mtxLoadPerspective(projection, 90, (float)m_reflectWidth / (float)m_reflectHeight,5.0,10000);
    
    mtxLoadIdentity(modelView);
    
    // Invert Y so that everything is rendered up-side-down
    // as it should with a reflection
    
    mtxScaleApply(modelView, 1, -1, 1);
    mtxTranslateApply(modelView, 0, 300, -800);
    mtxRotateXApply(modelView, -90.0f);
    mtxRotateApply(modelView, m_characterAngle, 0.7, 0.3, 1);
    
    mtxMultiply(mvp, projection, modelView);
    
    // Cull front faces now that everything is flipped
    // with our inverted reflection transformation matrix
    [self renderCharacter:mvp cullFace:GL_FRONT];
    
#endif // RENDER_REFLECTION
    
    // Bind our default FBO to render to the screen
    glBindFramebuffer(GL_FRAMEBUFFER, m_defaultFBOName);
    
    glViewport(0, 0, self.m_viewWidth, self.m_viewHeight);
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Calculate the projection matrix
    mtxLoadPerspective(projection, 90, (float)self.m_viewWidth / (float)self.m_viewHeight,5.0,10000);
    
    // Calculate the modelview matrix to render our character
    //  at the proper position and rotation
    mtxLoadTranslate(modelView, 0, 150, -450);
    mtxRotateXApply(modelView, -90.0f);
    mtxRotateApply(modelView, m_characterAngle, 0.7, 0.3, 1);
    
    // Multiply the modelview and projection matrix and set it in the shader
    mtxMultiply(mvp, projection, modelView);
    
    // Cull back faces now that we no longer render
    // with an inverted matrix
    [self renderCharacter:mvp cullFace:GL_BACK];
    
#if RENDER_REFLECTION
    
    // Use our shader for reflections
    glUseProgram(m_reflectPrgName);
    
    mtxLoadTranslate(modelView, 0, -50, -250);
    
    // Multiply the modelview and projection matrix and set it in the shader
    mtxMultiply(mvp, projection, modelView);
    
    // Set the modelview matrix that we calculated above
    // in our vertex shader
    glUniformMatrix4fv(m_reflectModelViewUniformIdx, 1, GL_FALSE, modelView);
    
    // Set the projection matrix that we calculated above
    // in our vertex shader
    glUniformMatrix4fv(m_reflectProjectionUniformIdx, 1, GL_FALSE, mvp);
    
    float normalMatrix[9];
    
    // Calculate the normal matrix so that we can
    // generate texture coordinates in our fragment shader
    
    // The normal matrix needs to be the inverse transpose of the
    //   top left 3x3 portion of the modelview matrix
    // We don't need to calculate the inverse transpose matrix
    //   here because this will always be an orthonormal matrix
    //   thus the the inverse tranpose is the same thing
    mtx3x3FromTopLeftOf4x4(normalMatrix, modelView);
    
    // Set the normal matrix for our shader to use
    glUniformMatrix3fv(m_reflectNormalMatrixUniformIdx, 1, GL_FALSE, normalMatrix);
    
    // Bind the texture we rendered-to above (i.e. the reflection texture)
    glBindTexture(GL_TEXTURE_2D, m_reflectTexName);
    
#if !ESSENTIAL_GL_PRACTICES_IOS
    // Generate mipmaps from the rendered-to base level
    //   Mipmaps reduce shimmering pixels due to better filtering
    // This call is not accelarated on iOS 4 so do not use
    //   mipmaps here
    glGenerateMipmap(GL_TEXTURE_2D);
#endif
    
    DwDrawVertexArray(&m_reflectVertexArray);
    
#endif // RENDER_REFLECTION
    
    // Update the angle so our character keeps spinning
    m_characterAngle++;
}

// Find the Uniform indices from character shaders.
- (void) findCharacterUniformIndices
{
    m_characterMvpUniformIdx = glGetUniformLocation(m_characterPrgName, "modelViewProjectionMatrix");
    
    if(m_characterMvpUniformIdx < 0)
    {
        NSLog(@"No modelViewProjectionMatrix in character shader");
    }
}

// Find the Uniform indices from relfect shaders.
- (void) findReflectUniformIndices
{
#if RENDER_REFLECTION

    m_reflectModelViewUniformIdx = glGetUniformLocation(m_reflectPrgName, "modelViewMatrix");
    
    if(m_reflectModelViewUniformIdx < 0)
    {
        NSLog(@"No modelViewMatrix in reflection shader");
    }
    
    m_reflectProjectionUniformIdx = glGetUniformLocation(m_reflectPrgName, "modelViewProjectionMatrix");
    
    if(m_reflectProjectionUniformIdx < 0)
    {
        NSLog(@"No modelViewProjectionMatrix in reflection shader");
    }
    
    m_reflectNormalMatrixUniformIdx = glGetUniformLocation(m_reflectPrgName, "normalMatrix");
    
    if(m_reflectNormalMatrixUniformIdx < 0)
    {
        NSLog(@"No normalMatrix in reflection shader");
    }
#endif
}

- (id) initWithDefaultFBO: (GLuint) defaultFBOName
{
    if((self = [super init]))
    {
        NSLog(@"%s %s", glGetString(GL_RENDERER), glGetString(GL_VERSION));
        
        ////////////////////////////////////////////////////
        // Build all of our and setup initial state here  //
        // Don't wait until our real time run loop begins //
        ////////////////////////////////////////////////////
        
        m_defaultFBOName = defaultFBOName;
        
        self.m_viewWidth = 100;
        self.m_viewHeight = 100;
        
        
        m_characterAngle = 0;
        
        NSString* filePathName = nil;
        
        //////////////////////////////
        // Load our character model //
        //////////////////////////////
        
        filePathName = [[NSBundle mainBundle] pathForResource:@"demon" ofType:@"model"];
        DwModel *characterModel = mdlLoadModel([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
        
        GLboolean usesVAOs = USE_VERTEX_BUFFER_OBJECTS;
        
        m_characterVertexArray.create(characterModel, usesVAOs);
        
        ////////////////////////////////////
        // Load texture for our character //
        ////////////////////////////////////
        
        filePathName = [[NSBundle mainBundle] pathForResource:@"demon" ofType:@"png"];
        DwImage *image = imgLoadImage([filePathName cStringUsingEncoding:NSASCIIStringEncoding], false);
        
        // Build a texture object with our image data
        m_characterTexName = buildTexture(image);
        
        // We can destroy the image once it's loaded into GL
        imgDestroyImage(image);
        
        
        ////////////////////////////////////////////////////
        // Load and Setup shaders for character rendering //
        ////////////////////////////////////////////////////
        
        DwResource vtxSource;
        DwResource frgSource;
        
        filePathName = [[NSBundle mainBundle] pathForResource:@"character" ofType:@"vsh"];
        vtxSource.loadFromFile([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
        
        filePathName = [[NSBundle mainBundle] pathForResource:@"character" ofType:@"fsh"];
        frgSource.loadFromFile([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
        
        // Build Program
        m_characterPrgName = DwBuildGLProgram(&vtxSource, &frgSource, NO, YES);
        
        [self findCharacterUniformIndices];
        
#if RENDER_REFLECTION
        
        m_reflectWidth = 512;
        m_reflectHeight = 512;
        
        ////////////////////////////////////////////////
        // Load a model for a quad for the reflection //
        ////////////////////////////////////////////////
        
        DwModel *quadModel = mdlLoadQuadModel();
        
        m_reflectVertexArray.create(quadModel, usesVAOs);
        
        /////////////////////////////////////////////////////
        // Create texture and FBO for reflection rendering //
        /////////////////////////////////////////////////////
        
        m_reflectFrameBuffer.create(m_reflectWidth, m_reflectHeight);
        
        // Get the texture we created in buildReflectFBO by binding the
        // reflection FBO and getting the buffer attached to color 0
        glBindFramebuffer(GL_FRAMEBUFFER, m_reflectFrameBuffer.getFrameBuffer());
        
        GLint iReflectTexName;
        
        glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                                              GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME,
                                              &iReflectTexName);
        
        m_reflectTexName = ((GLuint*)(&iReflectTexName))[0];
        
        /////////////////////////////////////////////////////
        // Load and setup shaders for reflection rendering //
        /////////////////////////////////////////////////////
        
        filePathName = [[NSBundle mainBundle] pathForResource:@"reflect" ofType:@"vsh"];
        vtxSource.loadFromFile([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
        
        filePathName = [[NSBundle mainBundle] pathForResource:@"reflect" ofType:@"fsh"];
        frgSource.loadFromFile([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
        
        // Build Program
        m_reflectPrgName = DwBuildGLProgram(&vtxSource, &frgSource, YES, NO);
        
        [self findReflectUniformIndices];
        
#endif // RENDER_REFLECTION
        
        ////////////////////////////////////////////////
        // Set up OpenGL state that will never change //
        ////////////////////////////////////////////////
        
        // Depth test will always be enabled
        glEnable(GL_DEPTH_TEST);
        
        // We will always cull back faces for better performance
        glEnable(GL_CULL_FACE);
        
        // Always use this clear color
        glClearColor(0.5f, 0.4f, 0.5f, 1.0f);
        
        // Draw our scene once without presenting the rendered image.
        //   This is done in order to pre-warm OpenGL
        // We don't need to present the buffer since we don't actually want the 
        //   user to see this, we're only drawing as a pre-warm stage
        [self render];
        
        // Reset the m_characterAngle which is incremented in render
        m_characterAngle = 0;
        
        // Check for errors to make sure all of our setup went ok
        GetGLError();
    }
    
    return self;
}


- (void) dealloc
{	
    // Cleanup all OpenGL objects and 
    glDeleteTextures(1, &m_characterTexName);
    glDeleteProgram(m_characterPrgName);
    
#if RENDER_REFLECTION
    glDeleteProgram(m_reflectPrgName);
    
#endif // RENDER_REFLECTION
    
    //  ARC forbids calling [super dealloc].  It is implemented automatically in ARC.
    //	[super dealloc];
}

@end
