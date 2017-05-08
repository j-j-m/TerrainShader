//
//  File.metal
//  Geosphere
//
//  Created by Jacob Martin on 4/17/17.
//  Copyright © 2017 Jacob Martin. All rights reserved.
//

#include <metal_stdlib>
#include "simplex2D.metal"
using namespace metal;

kernel void deformNormal(const device float3 *inVerts [[ buffer(0) ]],
                         device float3 *outVerts [[ buffer(1) ]],
                         device float3 *outNormals [[ buffer(2) ]],
                         uint id [[ thread_position_in_grid ]])
{
    
    if (id % 3 == 0) {
        
        const float3 v1 = inVerts[id];
        const float3 v2 = inVerts[id + 1];
        const float3 v3 = inVerts[id + 2];
        
        const float3 v12 = v2 - v1;
        const float3 v13 = v3 - v1;
        
        const float3 normal = fast::normalize(cross(v12, v13));
        
        outVerts[id] = v1;
        outVerts[id + 1] = v2;
        outVerts[id + 2] = v3;
        
        outNormals[id] = normal;
        outNormals[id + 1] = normal;
        outNormals[id + 2] = normal;
    }
}


struct DeformData {
    float3 location;
};



kernel void deformVertexNoise(const device float3 *inVerts [[ buffer(0) ]],
                              device float3 *outVerts [[ buffer(1) ]],
                              constant DeformData &deformD [[ buffer(2)]],
                              uint id [[ thread_position_in_grid ]])
{
    
    
    const float3 inVert = inVerts[id];
    
    float y_off = noisy((inVert.zx + deformD.location.zx) / 5000) * 20;
    y_off = y_off - snoise((inVert.xz + deformD.location.xz) / 50000) * 720;
    y_off = y_off + snoise((inVert.xz + deformD.location.xz) / 6000) * 580;
    y_off = y_off + noisy((inVert.zx + deformD.location.zx) / 50000) * 100;
    y_off = y_off + snoise((inVert.zx + deformD.location.zx) / 80000) * 800;
    
        const float3 outVert = float3(inVert.x, y_off ,inVert.z);
 
    
    outVerts[id] = outVert;
}

