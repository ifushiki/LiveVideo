//
//  VideoGLRenderer.m
//  LiveVideo
//
//  Created by IKKO FUSHIKI on 12/18/14.
//  Copyright (c) 2014 IKKO FUSHIKI. All rights reserved.
//

#import "VideoGLRenderer.h"

#import "../../DWCommon/DwStaticLib/DwStaticLib/DwStaticLib_cpp.h"
DwModel* mdlLoadVideoModel();

@interface VideoGLRenderer()
{
    GLuint m_Program;
    DwVertexArray m_vertexArray;
    GLint  m_fillColorUniformIdx;
}
@end

@implementation VideoGLRenderer

- (DwGLBaseRenderer *) createRenderer
{
    return [[VideoGLRenderer alloc] init];
}

// Find Uniform indices from the shaders.
- (void) findUniformIndices
{
    m_fillColorUniformIdx = glGetUniformLocation(m_Program, "fillColor1");
    
    if(m_fillColorUniformIdx < 0)
    {
        NSLog(@"No fillColor1 in shader");
    }
}

// Set the values of Unimforms in shaders.
- (void) setUniforms
{
    GLfloat color[4];
    color[0] = 1.0f;    // Red
    color[1] = 0.0f;    // Green
    color[2] = 0.0f;    // Blue
    color[3] = 1.0f;    // Alpha
    
    glUniform4fv(m_fillColorUniformIdx, 1, color);
}

- (id) init
{
    self = [super init];
    if (self) {
        GLboolean usesVAOs = true;
        DwModel *model = mdlLoadVideoModel();
        
        // Create a vertex array object.
        m_vertexArray.create(model, usesVAOs);
        
        NSString* filePathName = nil;
        DwResource vtxSource;
        DwResource frgSource;
        
        filePathName = [[NSBundle mainBundle] pathForResource:@"simple" ofType:@"vsh"];
        vtxSource.loadFromFile([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
        
        filePathName = [[NSBundle mainBundle] pathForResource:@"simple" ofType:@"fsh"];
        frgSource.loadFromFile([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
        
        // Build Program
        m_Program = DwBuildGLProgram(&vtxSource, &frgSource, NO, NO);
        
        // Find uniform index of shaders.
        [self findUniformIndices];
    }
    
    return self;
}

- (void) render
{
    glUseProgram(m_Program);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    glClearColor(1, 1, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Depth test will always be enabled
//    glDisable(GL_DEPTH_TEST);
//    glDisable(GL_CULL_FACE);
    // We will always cull back faces for better performance
    glViewport(0, 0, self.m_viewWidth, self.m_viewHeight);
    
    [self setUniforms];
    
    DwDrawVertexArray(&m_vertexArray);
}

- (void) dealloc
{
    glDeleteProgram(m_Program);
}


@end

DwModel* mdlLoadVideoModel()
{
    GLfloat posArray[] = {
        0.5f, 0.5f, -0.5f,          // 0
        -0.5f, 0.5f, -0.5f,         // 1
        -0.5f, -0.5f,  -0.5f,       // 2
        0.5f, -0.5f,  -0.5f,        // 3
        0.5f, 0.5f, 0.5f,           // 4
        -0.5f, 0.5f, 0.5f,          // 5
        -0.5f, -0.5f,  0.5f,        // 6
        0.5f, -0.5f,  0.5f          // 7
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
