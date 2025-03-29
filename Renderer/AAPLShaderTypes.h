//
//  AAPLShaderTypes.h
//  CustomRaytracerNew
//
//  Created by Ruben Glapa on 3/29/25.
//
#ifndef AAPLShaderTypes_h
#define AAPLShaderTypes_h

#include <simd/simd.h>

typedef enum AAPLConstantIndex
{
    AAPLConstantIndexRayTracingEnabled
} AAPLConstantIndex;

typedef enum RTReflectionKernelImageIndex
{
    OutImageIndex             = 0,
    ThinGBufferPositionIndex  = 1,
    ThinGBufferDirectionIndex = 2,
    IrradianceMapIndex        = 3
} RTReflectionKernelImageIndex;

typedef enum RTReflectionKernelBufferIndex
{
    SceneIndex                 = 0,
    AccelerationStructureIndex = 1
} RTReflectionKernelBufferIndex;

typedef enum BufferIndex
{
    BufferIndexMeshPositions      = 0,
    BufferIndexMeshGenerics       = 1,
    BufferIndexInstanceTransforms = 2,
    BufferIndexCameraData         = 3,
    BufferIndexLightData          = 4,
    BufferIndexSubmeshKeypath     = 5
} BufferIndex;

typedef enum VertexAttribute
{
    VertexAttributePosition = 0,
    VertexAttributeTexcoord = 1
} VertexAttribute;

// The attribute index values that the shader and the C code share to ensure Metal
// shader vertex attribute indices match the Metal API vertex descriptor attribute indices.
typedef enum AAPLVertexAttribute
{
    AAPLVertexAttributePosition  = 0,
    AAPLVertexAttributeTexcoord  = 1,
    AAPLVertexAttributeNormal    = 2,
    AAPLVertexAttributeTangent   = 3,
    AAPLVertexAttributeBitangent = 4
} AAPLVertexAttribute;
#endif // AAPLShaderTypes_h
