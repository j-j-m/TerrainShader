//
//  prog.metal
//  TerrainShader
//
//  Created by Jacob Martin on 5/6/17.
//  Copyright © 2017 Jacob Martin. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

#include <SceneKit/scn_metal>
#include "simplex2D.metal"


struct MyNodeBuffer {
    float4x4 modelTransform;
    float4x4 modelViewTransform;
    float4x4 normalTransform;
    float4x4 modelViewProjectionTransform;
};

typedef struct {
    float3 position [[ attribute(SCNVertexSemanticPosition) ]];
    float2 texCoords [[ attribute(SCNVertexSemanticTexcoord0) ]];
    float3 p [[ attribute(2) ]];
} MyVertexInput;

struct SimpleVertex
{
    float4 position [[position]];
    float2 texCoords;
    float3 p;
};

vertex SimpleVertex myVertex(MyVertexInput in [[ stage_in ]],
                             constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                             constant MyNodeBuffer& scn_node [[buffer(1)]])
{
    SimpleVertex vert;
    vert.p = in.position;
    vert.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    vert.texCoords = in.texCoords;
    
    return vert;
}

fragment half4 myFragment(SimpleVertex in [[stage_in]],
                          texture2d<float, access::sample> rockTexture [[texture(0)]],
                          texture2d<float, access::sample> grassTexture [[texture(1)]])
{
    constexpr sampler sampler2d(coord::normalized, filter::linear, address::repeat);
    
    float3 p = in.p;
    float4 tc = float4(snoise(p.xy/300), snoise(p.xy/300), snoise(p.xy/500), 1.0);
    
    float2 nt = float2(snoise(p.zx/10343), snoise(p.xy/2517));
    float2 nt2 = float2(snoise(p.zx/10345), snoise(p.xy/3500));
    float2 nt3 = float2(snoise(p.zx/500), snoise(p.xy/36));
    
    float4 color1 = rockTexture.sample(sampler2d, nt);
    float4 color2 = rockTexture.sample(sampler2d, nt2);
    
    float4 grass1 = grassTexture.sample(sampler2d, p.xz/100);
    float4 grass2 = grassTexture.sample(sampler2d, p.zx/100);
    
    float4 color3 = mix(grass1, grass2, snoise(p.xz/89)*2);
    
    float4 rockDist = mix(color1, color2, snoise(p.xy/10000)*2);
    float4 grassDist = color3;
    
    float4 y = 1.0 - p.y/700.0;
    return half4(mix(rockDist, grassDist, y));
}
