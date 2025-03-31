//
//  AAPLShaders.metal
//  CustomRaytracerNew
//
//  Created by Ruben Glapa on 3/29/25.
//

#include <metal_stdlib>
#include <simd/simd.h>

// Include the header that this Metal shader code shares with the Swift/C code that executes Metal API commands.
#include "AAPLShaderTypes.h"

#include "AAPLArgumentBufferTypes.h"

using namespace metal;

constant float PI = 3.1415926535897932384626433832795;
constant float kMaxHDRValue = 500.0f;

typedef struct
{
    float4 position [[position]];
    float3 ndcpos;
    float3 worldPosition;
    float3 normal;
    float3 tangent;
    float3 bitangent;
    float3 r;
    float2 texCoord;
} ColorInOut;

#pragma mark - Lighting

struct LightingParameters
{
    float3 lightDir;
    float3 viewDir;
    float3 halfVector;
    float3 reflectedVector;
    float3 normal;
    float3 reflectedColor;
    float3 irradiatedColor;
    float4 baseColor;
    float  nDoth;
    float  nDotv;
    float  nDotl;
    float  hDotl;
    float  metalness;
    float  roughness;
    float  ambientOcclusion;
};

constexpr sampler linearSampler (address::repeat,
                                 mip_filter::linear,
                                 mag_filter::linear,
                                 min_filter::linear);

constexpr sampler nearestSampler(address::repeat,
                                 min_filter::nearest,
                                 mag_filter::nearest,
                                 mip_filter::none);

inline float Fresnel(float dotProduct);
inline float sqr(float a);
float3 computeSpecular(LightingParameters parameters);
float Geometry(float Ndotv, float alphaG);
float3 computerNormalMap(ColorInOut in, texture2d<float> normalMapTexture);
float3 computeDiffuse(LightingParameters parameters);
float Distribution(float NdotH, float roughness);

inline float Fresnel(float dotProduct) {
    return pow(clamp(1.0 - dotProduct, 0.0, 1.0), 5.0);
}

inline float sqr(float a) {
    return a * a;
}

float Geometry(float Ndotv, float alphaG) {
    float a = alphaG * alphaG;
    float b = Ndotv * Ndotv;
    return (float)(1.0 / (Ndotv + sqrt(a + b - a*b)));
}

float3 computeNormalMap(ColorInOut in, texture2d<float> normalMapTexture) {
    float4 encodedNormal = normalMapTexture.sample(nearestSampler, float2(in.texCoord));
    float4 normalMap = float4(normalize(encodedNormal.xyz * 2.0 - float3(1,1,1)), 0.0);
    return float3(normalize(in.normal * normalMap.z + in.tangent * normalMap.x + in.bitangent * normalMap.y));
}

float3 computeDiffuse(LightingParameters parameters)
{
    float3 diffuseRawValue = float3(((1.0/PI) * parameters.baseColor) * (1.0 - parameters.metalness));
    return diffuseRawValue * (parameters.nDotl * parameters.ambientOcclusion);
}

float Distribution(float NdotH, float roughness) {
    if (roughness >= 1.0)
        return 1.0 / PI;
    
    float roughnessSqr = saturate(roughness * roughness);
    
    float d = (NdotH * roughnessSqr - NdotH) * NdotH + 1;
    return roughnessSqr / (PI * d * d);
}

float3 computeSpecular(LightingParameters parameters) {
    float specularRoughness = saturate(parameters.roughness * (1.0 - parameters.metalness) + parameters.metalness);
    
    float Ds = Distribution(parameters.nDoth, specularRoughness);
    
    float3 Cspec0 = parameters.baseColor.rgb;
    float3 Fs = float3(mix(float3(Cspec0), float3(1), Fresnel(parameters.hDotl)));
    float alphaG = sqr(specularRoughness * 0.5 + 0.5);
    float Gs = Geometry(parameters.nDotl, alphaG) * Geometry(parameters.nDotv, alphaG);
    
    float3 specularOutput = (Ds * Gs * Fs * parameters.irradiatedColor) * (1.0 + parameters.metalness * float3(parameters.baseColor)) + float3(parameters.metalness) * parameters.irradiatedColor * float3(parameters.baseColor);
    
    return specularOutput * parameters.ambientOcclusion;
}

// The helper for the equirectangular textures.
float4 equirectangularSample(float3 direction, sampler s, texture2d<float> image)
{
    float3 d = normalize(direction);
    
    float2 t = float2((atan2(d.z, d.x) + M_PI_F) / (2.f * M_PI_F), acos(d.y) / M_PI_F);
    
    return image.sample(s,t);
}

LightingParameters calculateParameters(ColorInOut in,
                                       AAPLCameraData cameraData,
                                       constant AAPLLightData& lightData,
                                       texture2d<float> baseColorMap,
                                       texture2d<float> normalMap,
                                       texture2d<float> metallicMap,
                                       texture2d<float> roughnessMap,
                                       texture2d<float> ambientOcclusionMap,
                                       texture2d<float> skydomeMap)
{
    LightingParameters parameters;
    
    parameters.baseColor = baseColorMap.sample(linearSampler, in.texCoord.xy);
    
    parameters.normal = computeNormalMap(in, normalMap);
    
    parameters.viewDir = normalize(cameraData.cameraPosition - float3(in.worldPosition));
    
    parameters.roughness = max(roughnessMap.sample(linearSampler, in.texCoord.xy).x, 0.001f) * 0.8;
    
    parameters.metalness = max(metallicMap.sample(linearSampler, in.texCoord.xy).x, 0.1);
    
    parameters.ambientOcclusion = ambientOcclusionMap.sample(linearSampler, in.texCoord.xy).x;
    
    parameters.reflectedVector = reflect(-parameters.viewDir, parameters.normal);
    
    constexpr sampler linearFilterSampler(coord::normalized, address::clamp_to_edge, filter::linear);
    float3 c = equirectangularSample(parameters.reflectedVector, linearFilterSampler, skydomeMap).rgb;
    parameters.irradiatedColor = clamp(c, 0.f, kMaxHDRValue);
    
    parameters.lightDir = lightData.directionalLightInvDirection;
    parameters.nDotl = max(0.001f, saturate(dot(parameters.normal, parameters.lightDir)));
    
    parameters.halfVector = normalize(parameters.lightDir + parameters.viewDir);
    parameters.nDoth = max(0.001f,saturate(dot(parameters.normal, parameters.halfVector)));
    parameters.nDotv = max(0.001f,saturate(dot(parameters.normal, parameters.viewDir)));
    parameters.hDotl = max(0.001f,saturate(dot(parameters.lightDir, parameters.halfVector)));
    
    return parameters;
}

#pragma mark - Skybox

struct SkyboxVertex
{
    float3 position [[attribute(AAPLVertexAttributePosition)]];
    float2 texcoord [[attribute(AAPLVertexAttributeTexcoord)]];
};

struct SkyboxV2F
{
    float4 position [[position]];
    float4 cameraToPointV;
    float2 texcoord;
    float y;
};

vertex SkyboxV2F skyboxVertex(SkyboxVertex in [[stage_in]],
                              constant AAPLCameraData& cameraData [[buffer(BufferIndexCameraData)]])
{
    SkyboxV2F v;
    v.cameraToPointV = cameraData.viewMatrix * float4(in.position, 1.0f);
    v.position = cameraData.projectionMatrix * v.cameraToPointV;
    v.texcoord = in.texcoord;
    v.y = v.cameraToPointV.y / v.cameraToPointV.w;
    return v;
}

fragment float4 skyboxFragment(SkyboxV2F v [[stage_in]], texture2d<float> skytexture [[texture(0)]])
{
    constexpr sampler linearFilterSampler(coord::normalized, address::clamp_to_edge, filter::linear);
    float3 c = equirectangularSample(v.cameraToPointV.xyz/v.cameraToPointV.w, linearFilterSampler, skytexture).rgb;
    return float4(clamp(c, 0.f, kMaxHDRValue), 1.f);
}

#pragma mark - Rasterization

typedef struct
{
    float3 position   [[attribute(AAPLVertexAttributePosition)]];
    float2 texCoord   [[attribute(AAPLVertexAttributeTexcoord)]];
    float3 normal     [[attribute(AAPLVertexAttributeNormal)]];
    float3 tangent    [[attribute(AAPLVertexAttributeTangent)]];
    float3 bitangent  [[attribute(AAPLVertexAttributeBitangent)]];
} Vertex;


