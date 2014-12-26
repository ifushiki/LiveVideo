//
//  VideoGLRenderer.m
//  LiveVideo
//
//  Created by IKKO FUSHIKI on 12/18/14.
//  Copyright (c) 2014 IKKO FUSHIKI. All rights reserved.
//

#import "VideoGLRenderer.h"
#import "VideoGLView.h"
#import "../../DWCommon/DwStaticLib/DwStaticLib/DwStaticLib_cpp.h"

// Toggle this to disable vertex buffer objects
// (i.e. use client-side vertex array objects)
// This must be 1 if using the GL3 Core Profile on the Mac
#define USE_VERTEX_BUFFER_OBJECTS 1

DwModel* mdlLoadTestModel();

@implementation VideoGLRenderer

DwVertexArray m_characterVertexArray;
GLuint m_characterPrgName;
GLuint m_characterTexName;

GLint m_characterMvpUniformIdx;
GLfloat m_characterAngle;

//GLboolean m_useVBOs;

- (void) renderCharacter:(GLfloat *) mvp cullFace:(GLuint) cullDirection withView:(DwGLBaseView *) itsView
{
    if (!itsView)
        return;
    
//    VideoGLView *glView = (VideoGLView *) itsView;

//    if (glView.imagePipe && [glView.imagePipe isReadyToReceiveNewData] == NO) {
 
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

//        [glView.imagePipe setReadyToReceiveNewData:YES];
//    }
}

- (void) render:(DwGLBaseView *) itsView
{
    // Set up the modelview and projection matricies
    GLfloat modelView[16];
    GLfloat projection[16];
    GLfloat mvp[16];
    
    // Bind our default FBO to render to the screen
    glBindFramebuffer(GL_FRAMEBUFFER, m_defaultFBOName);
    
    glViewport(0, 0, self.m_viewWidth, self.m_viewHeight);
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Calculate the projection matrix
//    mtxLoadPerspective(projection, 90, (float)self.m_viewWidth / (float)self.m_viewHeight,5.0,10000);
//    mtxLoadPerspective(projection, 90, (float)self.m_viewWidth / (float)self.m_viewHeight,5.0,1000);
    mtxLoadPerspective(projection, 45, (float)self.m_viewWidth / (float)self.m_viewHeight,5.0,1000);
    
    // Calculate the modelview matrix to render our character
    //  at the proper position and rotation
//    mtxLoadTranslate(modelView, 0, 150, -450);
    mtxLoadTranslate(modelView, 0, 0, -200);
    mtxRotateXApply(modelView, 90.0f);
//    mtxRotateApply(modelView, m_characterAngle, 0.7, 0.3, 1);
    mtxRotateApply(modelView, m_characterAngle, 0.2, 0.3, 1);
    
    // Multiply the modelview and projection matrix and set it in the shader
    mtxMultiply(mvp, projection, modelView);
    
    // Cull back faces now that we no longer render
    // with an inverted matrix
    [self renderCharacter:mvp cullFace:GL_BACK withView:itsView];
    
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
}

- (id) initWithDefaultFBO: (GLuint) defaultFBOName withView:(DwGLBaseView *)itsVew
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
        
//        filePathName = [[NSBundle mainBundle] pathForResource:@"demon" ofType:@"model"];
//        DwModel *characterModel = mdlLoadModel([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
//        DwModel *characterModel = mdlLoadTestModel();
        float radius = 50;
        float height = 100;
        int n = 12;
        DwModel *characterModel = createCylinderModel(radius, height, n);
        GLboolean usesVAOs = USE_VERTEX_BUFFER_OBJECTS;
        
        m_characterVertexArray.create(characterModel, usesVAOs);
        
        ////////////////////////////////////
        // Load texture for our character //
        ////////////////////////////////////
        
//        filePathName = [[NSBundle mainBundle] pathForResource:@"demon" ofType:@"png"];
//        filePathName = [[NSBundle mainBundle] pathForResource:@"MapEarth" ofType:@"jpg"];
        filePathName = [[NSBundle mainBundle] pathForResource:@"face2" ofType:@"jpg"];
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
        [self render:itsVew];
        
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
    
    //  ARC forbids calling [super dealloc].  It is implemented automatically in ARC.
    //	[super dealloc];
}

DwModel* createCylinderModel(float radius, float height, int n)
{
    DwModel* model = (DwModel*) calloc(sizeof(DwModel), 1);
    
    if(model == NULL || radius <= 0.0f || height <= 0.0f || n <= 0)
    {
        return NULL;
    }
    
    GLfloat *posArray = NULL;
    GLfloat *normalArray = NULL;
    GLfloat *textcoordArray = NULL;
    GLushort *elementArray = NULL;
    
    GLfloat posArraySize = sizeof(GLfloat)*((n+1)*6 + 2*3);
    GLfloat normArraySize = posArraySize;
    GLfloat texArraySize = sizeof(GLfloat)*((n+1)*4 + 2*2);
    GLushort elemArraySize = sizeof(GLushort)*(n*6 + n*6);
    
    posArray = (GLfloat *) malloc(posArraySize);
    normalArray = (GLfloat *) malloc(normArraySize);
    textcoordArray = (GLfloat *) malloc(texArraySize);
    elementArray = (GLushort *) malloc(elemArraySize);
    
    if (!posArray || !normalArray || !textcoordArray || !elementArray) {
        free(posArray);
        free(normalArray);
        free(textcoordArray);
        free(elementArray);
        free(model);
        
        return NULL;
    }
    
    // When it comes to here, all the memory was allocated successfully.
    float theta = 0;
    float dTheta = 2*M_PI/n;
    float dZ = height/2;
    GLfloat *pPos = posArray;
    GLfloat *pNorm = normalArray;
    GLfloat *pTex = textcoordArray;
    GLfloat xTex = 0.0f;
    GLfloat dXTex = 1.0/n;

    // In order to prevent the glitch, i must go from 0 to n.
    for (int i = 0; i <= n; i++) {
        if (i == n)
            theta = 0.0f;   // Prevent the glitch.
        GLfloat c = cos(theta);
        GLfloat s = sin(theta);
        GLfloat x = radius*c;
        GLfloat y = radius*s;
        
        // Corresponding location at the top and bottom rings.
        *pPos = x;
        pPos++;
        *pPos = y;
        pPos++;
        *pPos = - dZ;
        pPos++;
        *pPos = x;
        pPos++;
        *pPos = y;
        pPos++;
        *pPos = dZ;
        pPos++;

        // Corresponding normal at the top and bottom rings.
        *pNorm = c;
        pNorm++;
        *pNorm = s;
        pNorm++;
        *pNorm = 0.0f;
        pNorm++;
        *pNorm = c;
        pNorm++;
        *pNorm = s;
        pNorm++;
        *pNorm = 0.0f;
        pNorm++;
        
        // Corresponding texture coordinates at the top and bottom rings.
        if (i == n)
            xTex = 1.0f;
        
        *pTex = xTex;
        pTex++;
        *pTex = 0.0f;
        pTex++;
        *pTex = xTex;
        pTex++;
        *pTex = 1.0f;
        pTex++;
        
        theta += dTheta;
        xTex += dXTex;
    }
    
    // Add the center points.
    *pPos = 0.0f;
    pPos++;
    *pPos = 0.0f;
    pPos++;
    *pPos = - dZ;
    pPos++;
    *pPos = 0.0f;
    pPos++;
    *pPos = 0.0f;
    pPos++;
    *pPos = dZ;
 
    *pNorm = 0.0f;
    pNorm++;
    *pNorm = 0.0f;
    pNorm++;
    *pNorm = -1.0f;
    pNorm++;
    *pNorm = 0.0f;
    pNorm++;
    *pNorm = 0.0f;
    pNorm++;
    *pNorm = 1.0f;
    pNorm++;

    *pTex = 0.5;
    pTex++;
    *pTex = 0.0f;
    pTex++;
    *pTex = 0.5;
    pTex++;
    *pTex = 1.0f;
    pTex++;    
    
    int k = 0;
    int i0 = 0;
    for (int i = 0; i < n; i++) {
        elementArray[k++] = i0;
        elementArray[k++] = i0 + 3;
        elementArray[k++] = i0 + 1;
        elementArray[k++] = i0;
        elementArray[k++] = i0 + 2;
        elementArray[k++] = i0 + 3;
        i0 += 2;
    }

    // Add the  bottom and top triangles.
    int iBottom = 2*n;
    int iTop = iBottom + 1;
    
    i0 = 0;
    for (int i = 0; i < n; i++) {
        elementArray[k++] = iBottom;
        elementArray[k++] = i0 + 2;
        elementArray[k++] = i0;
        elementArray[k++] = iTop;
        elementArray[k++] = i0 + 1;
        elementArray[k++] = i0 + 3;
        i0 += 2;
    }
    
    model->positions = (GLubyte *) posArray;
    model->positionArraySize = posArraySize;
    model->positionType = GL_FLOAT;
    model->positionSize = 3;
    model->dataInfo |= DW_MODEL_DATA_INFO_POSITIONS; // positions data is independent.
    
    model->normals = (GLubyte *) normalArray;
    model->normalArraySize = normArraySize;
    model->normalType = GL_FLOAT;
    model->normalSize = 3;
    model->dataInfo |= DW_MODEL_DATA_INFO_NORMALS; // normals data is independent.
    
    model->texcoords = (GLubyte *) textcoordArray;
    model->texcoordArraySize = texArraySize;
    model->texcoordType = GL_FLOAT;
    model->texcoordSize = 2;
    model->dataInfo |= DW_MODEL_DATA_INFO_TEXCOORDS; // texcoords data is independent.
    
    model->elements	= (GLubyte*) elementArray;
    model->elementArraySize = elemArraySize;
    model->primType = GL_TRIANGLES;
    model->dataInfo |= DW_MODEL_DATA_INFO_ELEMENTS; // elements data is independent.
    
    model->numElements = elemArraySize/sizeof(GLushort);
    model->elementType = GL_UNSIGNED_SHORT;
    model->numVertcies = model->positionArraySize / (model->positionSize * sizeof(GLfloat));

    return model;
}

DwModel* mdlLoadTestModel()
{
    GLfloat posArray[] = {
        50.0f, 50.0f, -50.0f,          // 0
        -50.0f, 50.0f, -50.0f,         // 1
        -50.0f, -50.0f,  -50.0f,       // 2
        50.0f, -50.0f,  -50.0f,        // 3
        50.0f, 50.0f, 50.0f,           // 4
        -50.0f, 50.0f, 50.0f,          // 5
        -50.0f, -50.0f,  50.0f,        // 6
        50.0f, -50.0f,  50.0f          // 7
    };
    
    GLfloat texcoordArray[] = {
        0.00f,  0.0f,
        0.25f,  0.0f,
        0.50f,  0.0f,
        0.75f,  0.0f,
        0.00f,  1.0f,
        0.25f,  1.0f,
        0.50f,  1.0f,
        0.75f,  1.0f
    };
    
    GLfloat normalArray[] = {
        0.7071f, 0.7071f, 0.0f,
        -0.7071f, 0.7071f, 0.0f,
        -0.7071f, -0.7071f, 0.0f,
        0.7071f, -0.7071f, 0.0f,
        0.7071f, 0.7071f, 0.0f,
        -0.7071f, 0.7071f, 0.0f,
        -0.7071f, -0.7071f, 0.0f,
        0.7071f, -0.7071f, 0.0f
    };
    
    GLushort elementArray[] =
    {
        0, 1, 4, 4, 1, 5,
        1, 2, 5, 5, 2, 6,
        2, 3, 6, 6, 3, 7,
        3, 0, 7, 7, 0, 4,
        0, 2, 1, 0, 3, 2,   // Bottom
        4, 5, 6, 4, 6, 7    // Top
    };
    
    DwModel* model = (DwModel*) calloc(sizeof(DwModel), 1);
    
    if(NULL == model)
    {
        return NULL;
    }
    
    model->positionType = GL_FLOAT;
    model->positionSize = 3;
    model->positionArraySize = sizeof(posArray);
    model->positions = (GLubyte*)malloc(model->positionArraySize);
    memcpy(model->positions, posArray, model->positionArraySize);
    model->dataInfo |= DW_MODEL_DATA_INFO_POSITIONS; // positions data is independent.
    
    
    model->texcoordType = GL_FLOAT;
    model->texcoordSize = 2;
    model->texcoordArraySize = sizeof(texcoordArray);
    model->texcoords = (GLubyte*)malloc(model->texcoordArraySize);
    memcpy(model->texcoords, texcoordArray, model->texcoordArraySize );
    model->dataInfo |= DW_MODEL_DATA_INFO_TEXCOORDS; // texcoords data is independent.
    
    model->normalType = GL_FLOAT;
    model->normalSize = 3;
    model->normalArraySize = sizeof(normalArray);
    model->normals = (GLubyte*)malloc(model->normalArraySize);
    memcpy(model->normals, normalArray, model->normalArraySize);
    model->dataInfo |= DW_MODEL_DATA_INFO_NORMALS; // normals data is independent.
    
    model->elementArraySize = sizeof(elementArray);
    model->elements	= (GLubyte*)malloc(model->elementArraySize);
    memcpy(model->elements, elementArray, model->elementArraySize);
    model->dataInfo |= DW_MODEL_DATA_INFO_ELEMENTS; // elements data is independent.
    
    model->primType = GL_TRIANGLES;
    
    model->numElements = sizeof(elementArray) / sizeof(GLushort);
    model->elementType = GL_UNSIGNED_SHORT;
    model->numVertcies = model->positionArraySize / (model->positionSize * sizeof(GLfloat));
    
    return model;
}

@end
