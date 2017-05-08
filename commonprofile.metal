////////////////////////////////////////////////
// CommonProfile Shader v2

#import <metal_stdlib>

using namespace metal;

#ifndef __SCNMetalDefines__
#define __SCNMetalDefines__

enum {
    SCNVertexSemanticPosition,
    SCNVertexSemanticNormal,
    SCNVertexSemanticTangent,
    SCNVertexSemanticColor,
    SCNVertexSemanticBoneIndices,
    SCNVertexSemanticBoneWeights,
    SCNVertexSemanticTexcoord0,
    SCNVertexSemanticTexcoord1,
    SCNVertexSemanticTexcoord2,
    SCNVertexSemanticTexcoord3,
    SCNVertexSemanticTexcoord4,
    SCNVertexSemanticTexcoord5,
    SCNVertexSemanticTexcoord6,
    SCNVertexSemanticTexcoord7
};

// This structure hold all the informations that are constant through a render pass
// In a shader modifier, it is given both in vertex and fragment stage through an argument named "scn_frame".
struct SCNSceneBuffer {
    float4x4    viewTransform;
    float4x4    inverseViewTransform; // transform from view space to world space
    float4x4    projectionTransform;
    float4x4    viewProjectionTransform;
    float4x4    viewToCubeTransform; // transform from view space to cube texture space (canonical Y Up space)
    float4      ambientLightingColor;
    float4		fogColor;
    float3		fogParameters; // x:-1/(end-start) y:1-start*x z:exp
    float2      inverseResolution;
    float       time;
    float       sinTime;
    float       cosTime;
    float       random01;
    // new in macOS 10.12 and iOS 10
    float       environmentIntensity;
    float4x4    inverseProjectionTransform;
    float4x4    inverseViewProjectionTransform;
};

// In custom shaders or in shader modifiers, you also have access to node relative information.
// This is done using an argument named "scn_node", which must be a struct with only the necessary fields
// among the following list:
//
// float4x4 modelTransform;
// float4x4 inverseModelTransform;
// float4x4 modelViewTransform;
// float4x4 inverseModelViewTransform;
// float4x4 normalTransform; // This is the inverseTransposeModelViewTransform, need for normal transformation
// float4x4 modelViewProjectionTransform;
// float4x4 inverseModelViewProjectionTransform;
// float2x3 boundingBox;
// float2x3 worldBoundingBox;

#endif /* defined(__SCNMetalDefines__) */


//
// Utility
//

// Tool function

namespace scn {
    
    inline float3x3 mat3(float4x4 mat4)
    {
        return float3x3(mat4[0].xyz, mat4[1].xyz, mat4[2].xyz);
    }
    
    inline float3 mat4_mult_float3_normalized(float4x4 matrix, float3 src)
    {
        float3 dst  =  src.xxx * matrix[0].xyz;
        dst         += src.yyy * matrix[1].xyz;
        dst         += src.zzz * matrix[2].xyz;
        return normalize(dst);
    }
    
    inline float3 mat4_mult_float3(float4x4 matrix, float3 src)
    {
        float3 dst  =  src.xxx * matrix[0].xyz;
        dst         += src.yyy * matrix[1].xyz;
        dst         += src.zzz * matrix[2].xyz;
        return dst;
    }
    
    inline void generate_basis(float3 inR, thread float3 *outS, thread float3 *outT)
    {
        float3 dir = abs(inR.z) < 0.999 ? float3(0, 0, 1) : float3(1, 0, 0);
        *outS = normalize(cross(dir, inR));
        *outT = cross(inR, *outS);
    }
    
    // MARK: Drawing quads
    
    struct draw_quad_io_t {
        float4 position [[ position ]];
        float2 uv;
    };
    
}

inline float4 texture2DProj(texture2d<float> tex, sampler smp, float4 uv)
{
    return tex.sample(smp, uv.xy / uv.w);
}

inline float shadow2DProj(depth2d<float> tex, float4 uv)
{
    constexpr sampler linear_sampler(filter::linear, mip_filter::none, compare_func::greater_equal);
    //constexpr sampler linear_sampler(filter::linear, mip_filter::none, compare_func::none);
    float3 uvp = uv.xyz / uv.w;
    return tex.sample_compare(linear_sampler, uvp.xy, uvp.z);
}



// Inputs

typedef struct {
    
#ifdef USE_MODELTRANSFORM
    float4x4 modelTransform;
#endif
#ifdef USE_INVERSEMODELTRANSFORM
    float4x4 inverseModelTransform;
#endif
#ifdef USE_MODELVIEWTRANSFORM
    float4x4 modelViewTransform;
#endif
#ifdef USE_INVERSEMODELVIEWTRANSFORM
    float4x4 inverseModelViewTransform;
#endif
#ifdef USE_NORMALTRANSFORM
    float4x4 normalTransform;
#endif
#ifdef USE_MODELVIEWPROJECTIONTRANSFORM
    float4x4 modelViewProjectionTransform;
#endif
#ifdef USE_INVERSEMODELVIEWPROJECTIONTRANSFORM
    float4x4 inverseModelViewProjectionTransform;
#endif
#ifdef USE_BOUNDINGBOX
    float2x3 boundingBox;
#endif
#ifdef USE_WORLDBOUNDINGBOX
    float2x3 worldBoundingBox;
#endif
#ifdef USE_NODE_OPACITY
    float nodeOpacity;
#endif
#ifdef USE_DOUBLE_SIDED
    float orientationPreserved;
#endif
#if defined(USE_PROBES_LIGHTING) && (USE_PROBES_LIGHTING == 2)
    sh2_coefficients shCoefficients;
#elif defined(USE_PROBES_LIGHTING) && (USE_PROBES_LIGHTING == 3)
    sh3_coefficients shCoefficients;
#endif
#ifdef USE_SKINNING // need to be last since we may cut the buffer size based on the real bone number
    float4 skinningJointMatrices[765]; // Consider having a separate buffer ?
#endif
} commonprofile_node;

typedef struct {
    float3 position         [[attribute(SCNVertexSemanticPosition)]];
    float3 normal           [[attribute(SCNVertexSemanticNormal)]];
    float4 tangent          [[attribute(SCNVertexSemanticTangent)]];
    float4 color            [[attribute(SCNVertexSemanticColor)]];
    float4 skinningWeights  [[attribute(SCNVertexSemanticBoneWeights)]];
    uint4  skinningJoints   [[attribute(SCNVertexSemanticBoneIndices)]];
    float2 texcoord0        [[attribute(SCNVertexSemanticTexcoord0)]];
    float2 texcoord1        [[attribute(SCNVertexSemanticTexcoord1)]];
    float2 texcoord2        [[attribute(SCNVertexSemanticTexcoord2)]];
    float2 texcoord3        [[attribute(SCNVertexSemanticTexcoord3)]];
    float2 texcoord4        [[attribute(SCNVertexSemanticTexcoord4)]];
    float2 texcoord5        [[attribute(SCNVertexSemanticTexcoord5)]];
    float2 texcoord6        [[attribute(SCNVertexSemanticTexcoord6)]];
    float2 texcoord7        [[attribute(SCNVertexSemanticTexcoord7)]];
} scn_vertex_t; // __attribute__((scn_per_frame));

typedef struct {
    float4 fragmentPosition [[position]]; // The window relative coordinate (x, y, z, 1/w) values for the fragment
#ifdef USE_POINT_RENDERING
    float fragmentSize [[point_size]];
#endif
#ifdef USE_VERTEX_COLOR
    float4 vertexColor;
#endif
#ifdef USE_PER_VERTEX_LIGHTING
    float3 diffuse;
#ifdef USE_SPECULAR
    float3 specular;
#endif
#endif
#if defined(USE_POSITION) && (USE_POSITION == 2)
    float3 position;
#endif
#if defined(USE_NORMAL) && (USE_NORMAL == 2)
    float3 normal;
#endif
#if defined(USE_TANGENT) && (USE_TANGENT == 2)
    float3 tangent;
#endif
#if defined(USE_BITANGENT) && (USE_BITANGENT == 2)
    float3 bitangent;
#endif
#ifdef USE_NODE_OPACITY
    float nodeOpacity;
#endif
#ifdef USE_DOUBLE_SIDED
    float orientationPreserved;
#endif
#ifdef USE_TEXCOORD
    
#endif
    
} commonprofile_io;

struct SCNShaderSurface {
    float3 view;                // Direction from the point on the surface toward the camera (V)
    float3 position;            // Position of the fragment
    float3 normal;              // Normal of the fragment (N)
    float3 geometryNormal;      // Normal of the fragment - not taking into account normal map
    float2 normalTexcoord;      // Normal texture coordinates
    float3 tangent;             // Tangent of the fragment
    float3 bitangent;           // Bitangent of the fragment
    float4 ambient;             // Ambient property of the fragment
    float2 ambientTexcoord;     // Ambient texture coordinates
    float4 diffuse;             // Diffuse property of the fragment. Alpha contains the opacity.
    float2 diffuseTexcoord;     // Diffuse texture coordinates
    float4 specular;            // Specular property of the fragment
    float2 specularTexcoord;    // Specular texture coordinates
    float4 emission;            // Emission property of the fragment
    float2 emissionTexcoord;    // Emission texture coordinates
    float4 multiply;            // Multiply property of the fragment
    float2 multiplyTexcoord;    // Multiply texture coordinates
    float4 transparent;         // Transparent property of the fragment
    float2 transparentTexcoord; // Transparent texture coordinates
    float4 reflective;          // Reflective property of the fragment
    float  metalness;           // Metalness
    float2 metalnessTexcoord;   // Metalness texture coordinates
    float  roughness;           // Roughness
    float2 roughnessTexcoord;   // Metalness texture coordinates
    float shininess;            // Shininess property of the fragment.
    float fresnel;              // Fresnel property of the fragment.
    float ambientOcclusion;     // Ambient occlusion term of the fragment
    float3 _normalTS;           // UNDOCUMENTED in tangent space
#ifdef USE_SURFACE_EXTRA_DECL
    
#endif
};

struct SCNShaderLightingContribution {
    float3 ambient;
    float3 diffuse;
    float3 specular;
    float3 modulate;
};



// Structure to gather property of a light, packed to give access in a light shader modifier
struct SCNShaderLight {
    float4 intensity; // lowp, light intensity
    float3 direction; // mediump, vector from the point toward the light
    float  _att;
    float3 _spotDirection; // lowp, vector from the point to the light for point and spot, dist attenuations
    float  _distance; // mediump, distance from the point to the light (same coord. than range)
};

#ifdef USE_PBR

inline SCNPBRSurface SCNShaderSurfaceToSCNPBRSurface(SCNShaderSurface surface)
{
    SCNPBRSurface s;
    
    s.n = surface.normal;
    s.v = surface.view;
    s.albedo = surface.diffuse.xyz;
    
#ifdef USE_EMISSION
    s.emission = surface.emission.xyz;
#else
    s.emission = float3(0.);
#endif
    
    s.metalness = surface.metalness;
    s.roughness = surface.roughness;
    s.ao = surface.ambientOcclusion;
    return s;
}

static float4 scn_pbr_combine(SCNPBRSurface                      pbr_surface,
                              SCNShaderLightingContribution      lighting,
                              texture2d<float, access::sample>   specularDFG,
                              texturecube<float, access::sample> specularLD,
#ifdef USE_PROBES_LIGHTING
#if defined(USE_PROBES_LIGHTING) && (USE_PROBES_LIGHTING == 2)
                              sh2_coefficients                   shCoefficients,
#elif defined(USE_PROBES_LIGHTING) && (USE_PROBES_LIGHTING == 3)
                              sh3_coefficients                   shCoefficients,
#endif
#else
                              texturecube<float, access::sample> irradiance,
#endif
                              constant SCNSceneBuffer&           scn_frame)
{
#ifdef USE_PROBES_LIGHTING
    float3 pbr_color = scn_pbr_color_IBL(pbr_surface, specularDFG, specularLD, shCoefficients, scn_frame.viewToCubeTransform, scn_frame.environmentIntensity);
#else
    float3 pbr_color = scn_pbr_color_IBL(pbr_surface, specularDFG, specularLD, irradiance, scn_frame.viewToCubeTransform, scn_frame.environmentIntensity);
#endif
    
    float4 color;
    color.rgb = (lighting.ambient * pbr_surface.ao + lighting.diffuse) * pbr_surface.albedo.rgb + lighting.specular + pbr_color;
    
#if defined(USE_EMISSION) && !defined(USE_EMISSION_AS_SELFILLUMINATION)
    color.rgb += pbr_surface.emission.rgb;
#endif
    
    return color;
}

static void scn_pbr_lightingContribution(SCNShaderSurface                   surface,
                                         SCNShaderLight                     light,
                                         constant SCNSceneBuffer&           scn_frame,
                                         thread float3&                     lightingContributionDiffuse,
                                         thread float3&                     lightingContributionSpecular)
{
    SCNPBRSurface pbr_surface = SCNShaderSurfaceToSCNPBRSurface(surface);
    
    float3 diffuseOut, specularOut;
    scn_pbr_lightingContribution_pointLight(light.direction, pbr_surface.n, pbr_surface.v, pbr_surface.albedo, pbr_surface.metalness, pbr_surface.roughness, diffuseOut, specularOut);
    
    float3 lightFactor = light.intensity.rgb * light._att;
    lightingContributionDiffuse += diffuseOut * lightFactor;
    lightingContributionSpecular += specularOut * lightFactor;
}

#else // ifdef USE_PBR

inline float4 illuminate(SCNShaderSurface surface, SCNShaderLightingContribution lighting)
{
    float4 color = {0.,0.,0., surface.diffuse.a};
    
    float3 D = lighting.diffuse;
    
#if defined(USE_AMBIENT_LIGHTING) && (defined(LOCK_AMBIENT_WITH_DIFFUSE) || defined(USE_AMBIENT_AS_AMBIENTOCCLUSION))
    D += lighting.ambient * surface.ambientOcclusion;
#endif
    
#ifdef USE_EMISSION_AS_SELFILLUMINATION
    D += surface.emission.rgb;
#endif
    
    // Do we want to clamp there ????
    
    color.rgb = surface.diffuse.rgb * D;
#ifdef USE_SPECULAR
    float3 S = lighting.specular;
#elif defined(USE_REFLECTIVE)
    float3 S = float3(0.);
#endif
#ifdef USE_REFLECTIVE
    S += surface.reflective.rgb * surface.ambientOcclusion;
#endif
#ifdef USE_SPECULAR
    S *= surface.specular.rgb;
#endif
#if defined(USE_SPECULAR) || defined(USE_REFLECTIVE)
    color.rgb += S;
#endif
#if defined(USE_AMBIENT) && !defined(USE_AMBIENT_AS_AMBIENTOCCLUSION)
    color.rgb += surface.ambient.rgb * lighting.ambient;
#endif
#if defined(USE_EMISSION) && !defined(USE_EMISSION_AS_SELFILLUMINATION)
    color.rgb += surface.emission.rgb;
#endif
#ifdef USE_MULTIPLY
    color.rgb *= surface.multiply.rgb;
#endif
#ifdef USE_MODULATE
    color.rgb *= lighting.modulate;
#endif
    return color;
}
#endif

struct  commonprofile_lights {
#ifdef USE_LIGHTING
    float4 color0;
    float4 position0;
    
#endif
};


struct SCNShaderGeometry
{
    float4 position;
    float3 normal;
    float4 tangent;
    float4 color;
    float2 texcoords[8]; // MAX_UV
};

struct  commonprofile_uniforms {
    float4 diffuseColor;
    float4 specularColor;
    float4 ambientColor;
    float4 emissionColor;
    float4 reflectiveColor;
    float4 multiplyColor;
    float4 transparentColor;
    float metalness;
    float roughness;
    
    float diffuseIntensity;
    float specularIntensity;
    float normalIntensity;
    float ambientIntensity;
    float emissionIntensity;
    float reflectiveIntensity;
    float multiplyIntensity;
    float transparentIntensity;
    float metalnessIntensity;
    float roughnessIntensity;
    
    float materialShininess;
    float selfIlluminationOcclusion;
    float transparency;
    float3 fresnel; // x: ((n1-n2)/(n1+n2))^2 y:1-x z:exponent
    
#ifdef TEXTURE_TRANSFORM_COUNT
    float4x4 textureTransforms[TEXTURE_TRANSFORM_COUNT];
#endif
    
#if defined(USE_REFLECTIVE_CUBEMAP)
    //    float4x4 u_viewToCubeWorld;
#endif
};

// Shader modifiers declaration (only enabled if one modifier is present)
#ifdef USE_SHADER_MODIFIERS
// initial geometry is [-1,1] in XY plane (so z is always 0)
struct scn_floor_t {
    float3 u_floorNormal;
    float4 u_floorTangent;
    float3 u_floorCenter;
    float2 u_floorExtent;
};

#endif

// Vertex shader function

vertex commonprofile_io commonprofile_vert(scn_vertex_t in [[ stage_in ]],
                                           constant SCNSceneBuffer& scn_frame [[buffer(0)]],
#ifdef USE_INSTANCING
                                           // we use device here to override the 64Ko limit of constant buffers on NV hardware
                                           device commonprofile_node* scn_nodeInstances [[buffer(1)]]
                                           , uint instanceID [[ instance_id ]]
#else
                                           constant commonprofile_node& scn_node [[buffer(1)]]
#endif
#ifdef USE_PER_VERTEX_LIGHTING
                                           , constant commonprofile_lights& scn_lights [[buffer(2)]]
#endif
                                           // used for texture transform and materialShininess in case of perVertexLighting
                                           , constant commonprofile_uniforms& scn_commonprofile [[buffer(3)]]
#ifdef USE_VERTEX_EXTRA_ARGUMENTS
                                           , constant scn_floor_t& scn_fg [[buffer(4)]]
                                           
#endif
                                           )
{
#ifdef USE_INSTANCING
    device commonprofile_node& scn_node = scn_nodeInstances[instanceID];
#endif
    
    SCNShaderGeometry _geometry;
    // OPTIM in could be already float4?
    _geometry.position = float4(in.position, 1.0);
#ifdef USE_NORMAL
    _geometry.normal = in.normal;
#endif
#if defined(USE_TANGENT) || defined(USE_BITANGENT)
    _geometry.tangent = in.tangent;
#endif
#ifdef NEED_IN_TEXCOORD0
    _geometry.texcoords[0] = in.texcoord0;
#endif
#ifdef NEED_IN_TEXCOORD1
    _geometry.texcoords[1] = in.texcoord1;
#endif
#ifdef NEED_IN_TEXCOORD2
    _geometry.texcoords[2] = in.texcoord2;
#endif
#ifdef NEED_IN_TEXCOORD3
    _geometry.texcoords[3] = in.texcoord3;
#endif
#ifdef NEED_IN_TEXCOORD4
    _geometry.texcoords[4] = in.texcoord4;
#endif
#ifdef NEED_IN_TEXCOORD5
    _geometry.texcoords[5] = in.texcoord5;
#endif
#ifdef NEED_IN_TEXCOORD6
    _geometry.texcoords[6] = in.texcoord6;
#endif
#ifdef NEED_IN_TEXCOORD7
    _geometry.texcoords[7] = in.texcoord7;
#endif
#ifdef HAS_VERTEX_COLOR
    _geometry.color = in.color;
#elif USE_VERTEX_COLOR
    _geometry.color = float4(1.);
#endif
    
#ifdef USE_SKINNING
#if 0 // Alternate Skinning method, linear combining the joint matrices. Not fully tested yet
    {
        float4 joint0 = 0.;
        float4 joint1 = 0.;
        float4 joint2 = 0.;
        uint4 idx3 = in.skinningJoints * 3;
        for (int i = 0; i < MAX_BONE_INFLUENCES; ++i) {
            int idx = idx3[i];
#if MAX_BONE_INFLUENCES == 1
            float boneWeight = 1.;
#else
            float boneWeight = in.skinningWeights[i];
#endif
            joint0 += boneWeight * scn_node.skinningJointMatrices[idx];
            joint1 += boneWeight * scn_node.skinningJointMatrices[idx+1];
            joint2 += boneWeight * scn_node.skinningJointMatrices[idx+2];
        }
        float4x4 jointMatrix = float4x4(joint0, joint1, joint2, float4(0., 0., 0., 1.));
        _geometry.position.xyz = (_geometry.position * jointMatrix).xyz;
#ifdef USE_NORMAL
        _geometry.normal = _geometry.normal * scn::mat3(jointMatrix);
#endif
#if defined(USE_TANGENT) || defined(USE_BITANGENT)
        _geometry.tangent.xyz = _geometry.tangent.xyz * scn::mat3(jointMatrix);
#endif
    }
#else
    {
        float3 pos = 0.0;
#ifdef USE_NORMAL
        float3 nrm = 0.0;
#endif
#if defined(USE_TANGENT) || defined(USE_BITANGENT)
        float3 tgt = 0.0;
#endif
        for (int i = 0; i < MAX_BONE_INFLUENCES; ++i) {
#if MAX_BONE_INFLUENCES == 1
            float weight = 1.0;
#else
            float weight = in.skinningWeights[i];
            if (weight <= 0.f)
                continue;
            
#endif
            int idx = int(in.skinningJoints[i]) * 3;
            float4x4 jointMatrix = float4x4(scn_node.skinningJointMatrices[idx],
                                            scn_node.skinningJointMatrices[idx+1],
                                            scn_node.skinningJointMatrices[idx+2],
                                            float4(0., 0., 0., 1.));
            
            pos += (_geometry.position * jointMatrix).xyz * weight;
#ifdef USE_NORMAL
            nrm += _geometry.normal * scn::mat3(jointMatrix) * weight;
#endif
#if defined(USE_TANGENT) || defined(USE_BITANGENT)
            tgt += _geometry.tangent.xyz * scn::mat3(jointMatrix) * weight;
#endif
        }
        
        _geometry.position.xyz = pos;
#ifdef USE_NORMAL
        _geometry.normal = nrm;
#endif
#if defined(USE_TANGENT) || defined(USE_BITANGENT)
        _geometry.tangent.xyz = tgt;
#endif
    }
#endif
#endif // USE_SKINNING
    
#ifdef USE_GEOMETRY_MODIFIER
    // DoGeometryModifier START
    float3 u_floorNormal = scn_fg.u_floorNormal;
    float4 u_floorTangent = scn_fg.u_floorTangent;
    float3 u_floorCenter = scn_fg.u_floorCenter;
    float2 u_floorExtent = scn_fg.u_floorExtent;
    float3 floorBitangent =  normalize(cross(u_floorTangent.xyz, u_floorNormal));
    _geometry.position.xyz = u_floorCenter.xyz + u_floorExtent.x * (_geometry.position.x * u_floorTangent.xyz) + u_floorExtent.y * (_geometry.position.y * floorBitangent);
    _geometry.normal = u_floorNormal;
    _geometry.tangent = u_floorTangent;
    // we could check if the texCoord are really needed with ifdef USE_xxxx_MAP , or, better, work only on texcoordN [0..1]
    float2 tc;
    if (u_floorNormal.y != 0.)
        tc = _geometry.position.xz * 0.01;
    else if (u_floorNormal.z != 0.)
        tc = _geometry.position.xy * 0.01;
    else
        tc = _geometry.position.yz * 0.01;
    for (int i = 0; i < kSCNTexcoordCount; ++i)
        _geometry.texcoords[i] = tc;
    
    
    // DoGeometryModifier END
#endif
    
    // Transform the geometry elements in view space
#if defined(USE_POSITION) || defined(USE_NORMAL) || defined(USE_TANGENT) || defined(USE_BITANGENT) || defined(USE_INSTANCING)
    SCNShaderSurface _surface;
#endif
#if defined(USE_POSITION) || defined(USE_INSTANCING)
    _surface.position = (scn_node.modelViewTransform * _geometry.position).xyz;
#endif
#ifdef USE_NORMAL
    _surface.normal = normalize(scn::mat3(scn_node.normalTransform) * _geometry.normal);
#endif
#if defined(USE_TANGENT) || defined(USE_BITANGENT)
    _surface.tangent = normalize(scn::mat3(scn_node.normalTransform) * _geometry.tangent.xyz);
    _surface.bitangent = _geometry.tangent.w * cross(_surface.tangent, _surface.normal); // no need to renormalize since tangent and normal should be orthogonal
    // old code : _surface.bitangent =  normalize(cross(_surface.normal,_surface.tangent));
#endif
    
    //if USE_VIEW is 2 we may also need to set _surface.view. todo: make USE_VIEW a mask
#ifdef USE_VIEW
    _surface.view = normalize(-_surface.position);
#endif
    
    commonprofile_io out;
    
#ifdef USE_PER_VERTEX_LIGHTING
    // Lighting
    SCNShaderLightingContribution _lightingContribution;
    _lightingContribution.diffuse = 0.;
#ifdef USE_SPECULAR
    _lightingContribution.specular = 0.;
    _surface.shininess = scn_commonprofile.materialShininess;
#endif
    
    out.diffuse = _lightingContribution.diffuse;
#ifdef USE_SPECULAR
    out.specular = _lightingContribution.specular;
#endif
#endif
    
#if defined(USE_POSITION) && (USE_POSITION == 2)
    out.position = _surface.position;
#endif
#if defined(USE_NORMAL) && (USE_NORMAL == 2)
    out.normal = _surface.normal;
#endif
#if defined(USE_TANGENT) && (USE_TANGENT == 2)
    out.tangent = _surface.tangent;
#endif
#if defined(USE_BITANGENT) && (USE_BITANGENT == 2)
    out.bitangent = _surface.bitangent;
#endif
#ifdef USE_VERTEX_COLOR
    out.vertexColor = _geometry.color;
#endif
#ifdef USE_TEXCOORD
    
#endif
    
#if defined(USE_POSITION) || defined(USE_INSTANCING)
    out.fragmentPosition = scn_frame.projectionTransform * float4(_surface.position, 1.);
#elif defined(USE_MODELVIEWPROJECTIONTRANSFORM) // this means that the geometry are still in model space : we can transform it directly to NDC space
    out.fragmentPosition = scn_node.modelViewProjectionTransform * _geometry.position;
#endif
#ifdef USE_NODE_OPACITY
    out.nodeOpacity = scn_node.nodeOpacity;
#endif
#ifdef USE_DOUBLE_SIDED
    out.orientationPreserved = scn_node.orientationPreserved;
#endif
#ifdef USE_POINT_RENDERING
    out.fragmentSize = 1.;
#endif
    return out;
}

struct SCNOutput
{
    float4 color;
};

// Fragment shader function
fragment half4 commonprofile_frag(commonprofile_io in [[stage_in]],
                                  constant commonprofile_uniforms& scn_commonprofile [[buffer(0)]],
                                  constant SCNSceneBuffer& scn_frame [[buffer(1)]]
#ifdef USE_PER_PIXEL_LIGHTING
                                  , constant commonprofile_lights& scn_lights [[buffer(2)]]
#endif
#ifdef USE_EMISSION_MAP
                                  , texture2d<float> u_emissionTexture [[texture(0)]]
                                  , sampler          u_emissionTextureSampler [[sampler(0)]]
#endif
#ifdef USE_AMBIENT_MAP
                                  , texture2d<float> u_ambientTexture [[texture(1)]]
                                  , sampler          u_ambientTextureSampler [[sampler(1)]]
#endif
#ifdef USE_DIFFUSE_MAP
                                  , texture2d<float> u_diffuseTexture [[texture(2)]]
                                  , sampler          u_diffuseTextureSampler [[sampler(2)]]
#endif
#ifdef USE_SPECULAR_MAP
                                  , texture2d<float> u_specularTexture [[texture(3)]]
                                  , sampler          u_specularTextureSampler [[sampler(3)]]
#endif
#ifdef USE_REFLECTIVE_MAP
                                  , texture2d<float> u_reflectiveTexture [[texture(4)]]
                                  , sampler          u_reflectiveTextureSampler [[sampler(4)]]
#elif defined(USE_REFLECTIVE_CUBEMAP)
                                  , texturecube<float> u_reflectiveTexture [[texture(4)]]
                                  , sampler            u_reflectiveTextureSampler [[sampler(4)]]
#endif
#ifdef USE_TRANSPARENT_MAP
                                  , texture2d<float> u_transparentTexture [[texture(5)]]
                                  , sampler          u_transparentTextureSampler [[sampler(5)]]
#endif
#ifdef USE_MULTIPLY_MAP
                                  , texture2d<float> u_multiplyTexture [[texture(6)]]
                                  , sampler          u_multiplyTextureSampler [[sampler(6)]]
#endif
#ifdef USE_NORMAL_MAP
                                  , texture2d<float> u_normalTexture [[texture(7)]]
                                  , sampler          u_normalTextureSampler [[sampler(7)]]
#endif
#ifdef USE_PBR
#ifdef USE_METALNESS_MAP
                                  , texture2d<float> u_metalnessTexture [[texture(3)]]
                                  , sampler          u_metalnessTextureSampler [[sampler(3)]]
#endif
#ifdef USE_ROUGHNESS_MAP
                                  , texture2d<float> u_roughnessTexture [[texture(4)]]
                                  , sampler          u_roughnessTextureSampler [[sampler(4)]]
#endif
                                  , texturecube<float> u_irradianceTexture [[texture(8)]]
                                  , texturecube<float> u_radianceTexture [[texture(9)]]
                                  , texture2d<float>   u_specularDFGTexture [[texture(10)]]
#endif
#ifdef USE_SSAO
                                  , texture2d<float> u_ssaoTexture [[texture(11)]]
#endif
                                  , constant commonprofile_node& scn_node [[buffer(3)]]
#ifdef USE_FRAGMENT_EXTRA_ARGUMENTS
                                  
#endif
#if defined(USE_DOUBLE_SIDED)
                                  , bool isFrontFacing [[front_facing]]
#endif
                                  )
{
    SCNShaderSurface _surface;
#ifdef USE_TEXCOORD
    
#endif
    _surface.ambientOcclusion = 1.f; // default to no AO
#ifdef USE_AMBIENT_MAP
#ifdef USE_AMBIENT_AS_AMBIENTOCCLUSION
    _surface.ambientOcclusion = u_ambientTexture.sample(u_ambientTextureSampler, _surface.ambientTexcoord).r;
#ifdef USE_AMBIENT_INTENSITY
    _surface.ambientOcclusion = saturate(mix(1., _surface.ambientOcclusion, scn_commonprofile.ambientIntensity));
#endif
#else // AMBIENT_MAP
    _surface.ambient = u_ambientTexture.sample(u_ambientTextureSampler, _surface.ambientTexcoord);
#ifdef USE_AMBIENT_INTENSITY
    _surface.ambient *= scn_commonprofile.ambientIntensity;
#endif
#endif // USE_AMBIENT_AS_AMBIENTOCCLUSION
#elif defined(USE_AMBIENT_COLOR)
    _surface.ambient = scn_commonprofile.ambientColor;
#elif defined(USE_AMBIENT)
    _surface.ambient = float4(0.);
#endif
#if defined(USE_AMBIENT) && defined(USE_VERTEX_COLOR)
    _surface.ambient *= in.vertexColor;
#endif
#if  defined(USE_SSAO)
    _surface.ambientOcclusion *= u_ssaoTexture.sample( sampler(filter::linear), in.fragmentPosition.xy * scn_frame.inverseResolution.xy ).x;
#endif
    
#ifdef USE_DIFFUSE_MAP
    _surface.diffuse = u_diffuseTexture.sample(u_diffuseTextureSampler, _surface.diffuseTexcoord);
#ifdef USE_DIFFUSE_INTENSITY
    _surface.diffuse.rgb *= scn_commonprofile.diffuseIntensity;
#endif
#elif defined(USE_DIFFUSE_COLOR)
    _surface.diffuse = scn_commonprofile.diffuseColor;
#else
    _surface.diffuse = float4(0.,0.,0.,1.);
#endif
#if defined(USE_DIFFUSE) && defined(USE_VERTEX_COLOR)
    _surface.diffuse *= in.vertexColor;
#endif
#ifdef USE_SPECULAR_MAP
    _surface.specular = u_specularTexture.sample(u_specularTextureSampler, _surface.specularTexcoord);
#ifdef USE_SPECULAR_INTENSITY
    _surface.specular *= scn_commonprofile.specularIntensity;
#endif
#elif defined(USE_SPECULAR_COLOR)
    _surface.specular = scn_commonprofile.specularColor;
#elif defined(USE_SPECULAR)
    _surface.specular = float4(0.);
#endif
#ifdef USE_EMISSION_MAP
    _surface.emission = u_emissionTexture.sample(u_emissionTextureSampler, _surface.emissionTexcoord);
#ifdef USE_EMISSION_INTENSITY
    _surface.emission *= scn_commonprofile.emissionIntensity;
#endif
#elif defined(USE_EMISSION_COLOR)
    _surface.emission = scn_commonprofile.emissionColor;
#elif defined(USE_EMISSION)
    _surface.emission = float4(0.);
#endif
#ifdef USE_MULTIPLY_MAP
    _surface.multiply = u_multiplyTexture.sample(u_multiplyTextureSampler, _surface.multiplyTexcoord);
#ifdef USE_MULTIPLY_INTENSITY
    _surface.multiply = mix(float4(1.), _surface.multiply, scn_commonprofile.multiplyIntensity);
#endif
#elif defined(USE_MULTIPLY_COLOR)
    _surface.multiply = scn_commonprofile.multiplyColor;
#elif defined(USE_MULTIPLY)
    _surface.multiply = float4(1.);
#endif
#ifdef USE_TRANSPARENT_MAP
    _surface.transparent = u_transparentTexture.sample(u_transparentTextureSampler, _surface.transparentTexcoord);
#ifdef USE_TRANSPARENT_INTENSITY
    _surface.transparent *= scn_commonprofile.transparentIntensity;
#endif
#elif defined(USE_TRANSPARENT_COLOR)
    _surface.transparent = scn_commonprofile.transparentColor;
#elif defined(USE_TRANSPARENT)
    _surface.transparent = float4(1.);
#endif
    
#ifdef USE_METALNESS_MAP
    _surface.metalness = u_metalnessTexture.sample(u_metalnessTextureSampler, _surface.metalnessTexcoord).r;
#ifdef USE_METALNESS_INTENSITY
    _surface.metalness *= scn_commonprofile.metalnessIntensity;
#endif
#elif defined(USE_METALNESS_COLOR)
    _surface.metalness = scn_commonprofile.metalness;
#else
    _surface.metalness = 0;
#endif
    
#ifdef USE_ROUGHNESS_MAP
    _surface.roughness = u_roughnessTexture.sample(u_roughnessTextureSampler, _surface.roughnessTexcoord).r;
#ifdef USE_ROUGHNESS_INTENSITY
    _surface.roughness *= scn_commonprofile.roughnessIntensity;
#endif
#elif defined(USE_ROUGHNESS_COLOR)
    _surface.roughness = scn_commonprofile.roughness;
#else
    _surface.roughness = 0;
#endif
    
#if (defined USE_NORMAL) && (USE_NORMAL == 2)
#ifdef USE_DOUBLE_SIDED
    _surface.geometryNormal = normalize(in.normal.xyz) * in.orientationPreserved * ((float(isFrontFacing) * 2.0) - 1.0);
#else
    _surface.geometryNormal = normalize(in.normal.xyz);
#endif
    _surface.normal = _surface.geometryNormal;
#endif
#if defined(USE_TANGENT) && (USE_TANGENT == 2)
    _surface.tangent = in.tangent;
#endif
#if defined(USE_BITANGENT) && (USE_BITANGENT == 2)
    _surface.bitangent = in.bitangent;
#endif
#if (defined USE_POSITION) && (USE_POSITION == 2)
    _surface.position = in.position;
#endif
#if (defined USE_VIEW) && (USE_VIEW == 2)
    _surface.view = normalize(-in.position);
#endif
#ifdef USE_NORMAL_MAP
    float3x3 ts2vs = float3x3(_surface.tangent, _surface.bitangent, _surface.normal);
    _surface._normalTS = u_normalTexture.sample(u_normalTextureSampler, _surface.normalTexcoord).rgb * 2. - 1.;
    // _surface.normal.z = 1. - sqrt(_surface.normal.x * _surface.normal.x + _surface.normal.y * _surface.normal.y);
#ifdef USE_NORMAL_INTENSITY
    _surface._normalTS = mix(float3(0., 0., 1.), _surface._normalTS, scn_commonprofile.normalIntensity);
#endif
    // transform the normal in view space
    _surface.normal.rgb = normalize(ts2vs * _surface._normalTS);
#else
    _surface._normalTS = float3(0.);
#endif
    
#ifdef USE_REFLECTIVE_MAP
    float3 refl = reflect( -_surface.view, _surface.normal );
    float m = 2.0 * sqrt( refl.x*refl.x + refl.y*refl.y + (refl.z+1.0)*(refl.z+1.0));
    _surface.reflective = u_reflectiveTexture.sample(u_reflectiveTextureSampler, float2(float2(refl.x,-refl.y) / m) + 0.5);
#ifdef USE_REFLECTIVE_INTENSITY
    _surface.reflective *= scn_commonprofile.reflectiveIntensity;
#endif
#elif defined(USE_REFLECTIVE_CUBEMAP)
    float3 refl = reflect( _surface.position, _surface.normal );
    _surface.reflective = u_reflectiveTexture.sample(u_reflectiveTextureSampler, scn::mat4_mult_float3(scn_frame.viewToCubeTransform, refl)); // sample the cube map in world space
#ifdef USE_REFLECTIVE_INTENSITY
    _surface.reflective *= scn_commonprofile.reflectiveIntensity;
#endif
#elif defined(USE_REFLECTIVE_COLOR)
    _surface.reflective = scn_commonprofile.reflectiveColor;
#elif defined(USE_REFLECTIVE)
    _surface.reflective = float4(0.);
#endif
#ifdef USE_FRESNEL
    _surface.fresnel = scn_commonprofile.fresnel.x + scn_commonprofile.fresnel.y * pow(1.0 - saturate(dot(_surface.view, _surface.normal)), scn_commonprofile.fresnel.z);
    _surface.reflective *= _surface.fresnel;
#endif
#ifdef USE_SHININESS
    _surface.shininess = scn_commonprofile.materialShininess;
#endif
    
#ifdef USE_SURFACE_MODIFIER
    // DoSurfaceModifier START
    
    // DoSurfaceModifier END
#endif
    // Lighting
    SCNShaderLightingContribution _lightingContribution = {0};
    
    
    // Lighting
#ifdef USE_AMBIENT_LIGHTING
    _lightingContribution.ambient = scn_frame.ambientLightingColor.rgb;
#endif
    
#ifdef USE_LIGHTING
#ifdef USE_PER_PIXEL_LIGHTING
    _lightingContribution.diffuse = float3(0.);
#ifdef USE_MODULATE
    _lightingContribution.modulate = float3(1.);
#endif
#ifdef USE_SPECULAR
    _lightingContribution.specular = float3(0.);
#endif
    {
        SCNShaderLight _light;
        _light.intensity = scn_lights.color0;
        _light.direction = normalize(scn_lights.position0.xyz - _surface.position);
        _light._att = 1.;
        _light.intensity.rgb *= _light._att * max(0.f, dot(_surface.normal, _light.direction));
        _lightingContribution.diffuse += _light.intensity.rgb;
    }
    
#else // USE_PER_PIXEL_LIGHTING
    _lightingContribution.diffuse = in.diffuse;
#ifdef USE_SPECULAR
    _lightingContribution.specular = in.specular;
#endif
#endif
#ifdef AVOID_OVERLIGHTING
    _lightingContribution.diffuse = saturate(_lightingContribution.diffuse);
#ifdef USE_SPECULAR
    _lightingContribution.specular = saturate(_lightingContribution.specular);
#endif // USE_SPECULAR
#endif // AVOID_OVERLIGHTING
#else // USE_LIGHTING
    _lightingContribution.diffuse = float3(1.);
#endif // USE_LIGHTING
    
    // Combine
    SCNOutput _output;
#ifdef USE_PBR
    SCNPBRSurface pbr_surface = SCNShaderSurfaceToSCNPBRSurface(_surface);
    pbr_surface.selfIlluminationOcclusion = scn_commonprofile.selfIlluminationOcclusion;
#ifdef USE_PROBES_LIGHTING
    _output.color = scn_pbr_combine(pbr_surface, _lightingContribution, u_specularDFGTexture, u_radianceTexture, scn_node.shCoefficients, scn_frame);
#else
    _output.color = scn_pbr_combine(pbr_surface, _lightingContribution, u_specularDFGTexture, u_radianceTexture, u_irradianceTexture, scn_frame);
#endif
    _output.color.a = _surface.diffuse.a;
#else
    _output.color = illuminate(_surface, _lightingContribution);
#endif
    
#ifdef USE_FOG
    float fogFactor = pow(clamp(length(_surface.position.xyz) * scn_frame.fogParameters.x + scn_frame.fogParameters.y, 0., scn_frame.fogColor.a), scn_frame.fogParameters.z);
    _output.color.rgb = mix(_output.color.rgb, scn_frame.fogColor.rgb * _output.color.a, fogFactor);
#endif
    
#ifndef DIFFUSE_PREMULTIPLIED
    _output.color.rgb *= _surface.diffuse.a;
#endif
    
#ifdef USE_TRANSPARENT // Either a map or a color
    
#ifdef USE_TRANSPARENCY
    _surface.transparent *= scn_commonprofile.transparency;
#endif
    
#ifdef USE_TRANSPARENCY_RGBZERO
#ifdef USE_NODE_OPACITY
    _output.color *= in.nodeOpacity;
#endif
    // compute luminance
    _surface.transparent.a = (_surface.transparent.r * 0.212671) + (_surface.transparent.g * 0.715160) + (_surface.transparent.b * 0.072169);
    _output.color *= (float4(1.) - _surface.transparent);
#else // ALPHA_ONE
#ifdef USE_NODE_OPACITY
    _output.color *= (in.nodeOpacity * _surface.transparent.a);
#else
    _output.color *= _surface.transparent.a;
#endif
#endif
#else
#ifdef USE_TRANSPARENCY // TRANSPARENCY without TRANSPARENT slot (nodeOpacity + diffuse.a)
#ifdef USE_NODE_OPACITY
    _output.color *= (in.nodeOpacity * scn_commonprofile.transparency);
#else
    _output.color *= scn_commonprofile.transparency;
#endif // NODE_OPACITY
#endif
#endif
    
#ifdef USE_FRAGMENT_MODIFIER
    // DoFragmentModifier START
    
    // DoFragmentModifier END
#endif
    
    //#ifdef USE_SSAO
    //    _output.color.rgb = float3(_surface.ambientOcclusion);
    //#endif
    
#ifdef USE_DISCARD
    if (_output.color.a == 0.) // we could set a different limit here
        discard_fragment();
#endif
    
    return half4(_output.color);
}
