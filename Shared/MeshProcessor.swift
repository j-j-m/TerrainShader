//
//  MeshProcessor.swift
//  Geosphere
//
//  Created by Jacob Martin on 4/20/17.
//  Copyright © 2017 Jacob Martin. All rights reserved.
//

import Foundation
import Metal
import SceneKit

struct ShaderData {
    var location:vector_float3
}


class MeshProcessor {
    
    let device:MTLDevice
    
    var commandQueue:MTLCommandQueue!
    var defaultLibrary:MTLLibrary!
    var functionVertex:MTLFunction!
    var functionNormal:MTLFunction!
    var pipelineStateVertex: MTLComputePipelineState!
    var pipelineStateNormal: MTLComputePipelineState!
    
    init(device:MTLDevice) {
        self.device = device
        setupMetal()
    }
    
    func setupMetal() {
        commandQueue = device.makeCommandQueue()
        
        defaultLibrary = device.newDefaultLibrary()
        functionVertex = defaultLibrary.makeFunction(name: "deformVertexNoise")
        functionNormal = defaultLibrary.makeFunction(name: "deformNormal")
        
        do {
            pipelineStateVertex = try! device.makeComputePipelineState(function: functionVertex)
            pipelineStateNormal = try! device.makeComputePipelineState(function: functionNormal)
        }
    }
    
    func getBestThreadCount(_ count:Int) -> Int {
        
        /*
         The normal compute shader hangs the app if the total thread count doesn't match
         the number of faces (3 vertexes). So use this method to get the highest multiple
         of both 3 and the vertex count. Obviously you'll get better performance if the
         mesh vertex count is divisible by 30.
         */
        //TODO - make this better
        
        if (count % 30 == 0) {
            return 30
        } else if (count % 27 == 0) {
            return 27
        } else if (count % 24 == 0) {
            return 24
        } else if (count % 21 == 0) {
            return 21
        } else if (count % 18 == 0) {
            return 18
        } else if (count % 15 == 0) {
            return 15
        } else if (count % 12 == 0) {
            return 12
        } else if (count % 9 == 0) {
            return 9
        } else if (count % 6 == 0) {
            return 6
        } else {
            return 3
        }
    }
    
    func compute(_ mesh:MeshData, data:ShaderData) {
        var shaderData = data
        
        
        // Shader 1 - Vertex
        
        let computeCommandBuffer = commandQueue.makeCommandBuffer()
        let computeCommandEncoder = computeCommandBuffer.makeComputeCommandEncoder()
        
        computeCommandEncoder.setComputePipelineState(pipelineStateVertex)
        
        computeCommandEncoder.setBuffer(mesh.vertexBuffer1, offset: 0, at: 0)
        computeCommandEncoder.setBuffer(mesh.vertexBuffer2, offset: 0, at: 1)
        
        computeCommandEncoder.setBytes(&shaderData, length: MemoryLayout<ShaderData>.size, at: 2)
        
        let count = mesh.vertexCount
        let threadExecutionWidth = pipelineStateVertex.threadExecutionWidth
        let threadsPerGroup = MTLSize(width:threadExecutionWidth,height:1,depth:1)
        let ntg = Int(ceil(Float(count)/Float(threadExecutionWidth)))
        let numThreadgroups = MTLSize(width: ntg, height:1, depth:1)
        
        computeCommandEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
        computeCommandEncoder.endEncoding()
        computeCommandBuffer.commit()
        
        // Shader 2 - Normal
        
        let normalComputeCommandBuffer = commandQueue.makeCommandBuffer()
        let normalComputeCommandEncoder = normalComputeCommandBuffer.makeComputeCommandEncoder()
        
        normalComputeCommandEncoder.setComputePipelineState(pipelineStateNormal)
        
        normalComputeCommandEncoder.setBuffer(mesh.vertexBuffer2, offset: 0, at: 0)
        normalComputeCommandEncoder.setBuffer(mesh.vertexBuffer1, offset: 0, at: 1)
        
        normalComputeCommandEncoder.setBuffer(mesh.normalBuffer, offset: 0, at: 2)
        
        var maxThreads = pipelineStateNormal.threadExecutionWidth - pipelineStateNormal.threadExecutionWidth % 3
        maxThreads = min(mesh.vertexCount, maxThreads)
        
        let bestThreadsPerGroup = getBestThreadCount(mesh.vertexCount)
        let groupCount = mesh.vertexCount / bestThreadsPerGroup
        
        normalComputeCommandEncoder.dispatchThreadgroups(MTLSizeMake(groupCount,1,1), threadsPerThreadgroup: MTLSizeMake(bestThreadsPerGroup, 1, 1))
        normalComputeCommandEncoder.endEncoding()
        normalComputeCommandBuffer.commit()
        
    }
    
}
