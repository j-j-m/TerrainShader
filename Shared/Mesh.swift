//
//  Mesh.swift
//  Geosphere
//
//  Created by Jacob Martin on 4/17/17.
//  Copyright © 2017 Jacob Martin. All rights reserved.
//

import Foundation
import Metal
import SceneKit




struct MeshData {
    
    let geometry:SCNGeometry
    let vertexBuffer1:MTLBuffer
    let vertexBuffer2:MTLBuffer
    let normalBuffer:MTLBuffer
    let vertexCount:Int
    let indexList:[CInt]
    
    init(
        geometry:SCNGeometry,
        vertexCount:Int,
        indexList: [CInt],
        vertexBuffer1:MTLBuffer,
        vertexBuffer2:MTLBuffer,
        normalBuffer:MTLBuffer) {
        self.geometry = geometry
        self.vertexCount = vertexCount
        self.indexList = indexList
        self.vertexBuffer1 = vertexBuffer1
        self.vertexBuffer2 = vertexBuffer2
        self.normalBuffer = normalBuffer
    }
    
    
}




protocol Mesh {
    var meshData:MeshData { get }
}


//MARK: - Mesh Object


struct Plane: Mesh {
    
    var meshData: MeshData
    
    init(width:Float, length:Float, step:Float){
        
        let device = MTLCreateSystemDefaultDevice()!
        
        var pointsList: [vector_float3] = []
        var normalsList: [vector_float3] = []
        var uvList : [vector_float2] = []
        var indexList: [CInt] = []
        
        let normal = vector_float3(0, 1, 0)
        
        var zPrevious:Float? = nil
        var z:Float = 0
        while z <= length {
            
            var xPrevious:Float? = nil
            var x:Float = 0
            while x <= width {
                if let xPrevious = xPrevious, let zPrevious = zPrevious {
                    
                    let p0 = vector_float3(xPrevious, 0, zPrevious)
                    let p1 = vector_float3(xPrevious, 0, z)
                    let p2 = vector_float3(x, 0, z)
                    let p3 = vector_float3(x, 0, zPrevious)
                    
                    pointsList.append(p0)
                    normalsList.append(normal)
                    uvList.append(vector_float2(p0.x,p0.z))
                    indexList.append(CInt(indexList.count))
                    
                    pointsList.append(p1)
                    normalsList.append(normal)
                    uvList.append(vector_float2(p1.x,p1.z))
                    indexList.append(CInt(indexList.count))
                    
                    pointsList.append(p2)
                    normalsList.append(normal)
                    uvList.append(vector_float2(p2.x,p2.z))
                    indexList.append(CInt(indexList.count))
                    
                    
                    
                    pointsList.append(p0)
                    normalsList.append(normal)
                    uvList.append(vector_float2(p0.x,p0.z))
                    indexList.append(CInt(indexList.count))
                    
                    pointsList.append(p2)
                    normalsList.append(normal)
                    uvList.append(vector_float2(p1.x,p1.z))
                    indexList.append(CInt(indexList.count))
                    
                    pointsList.append(p3)
                    normalsList.append(normal)
                    uvList.append(vector_float2(p2.x,p2.z))
                    indexList.append(CInt(indexList.count))
                }
                
                xPrevious = x
                x=x+step
            }
            
            zPrevious = z
            z=z+step
        }
        
        let vertexFormat = MTLVertexFormat.float3
        //metal compute shaders cant read and write to same buffer, so make two of them
        //second one could be empty in this case
        let vertexBuffer1 = device.makeBuffer(
            bytes: pointsList,
            length: pointsList.count * MemoryLayout<vector_float3>.size,
            options: [.cpuCacheModeWriteCombined]
        )
        let vertexBuffer2 = device.makeBuffer(
            bytes: pointsList,
            length: pointsList.count * MemoryLayout<vector_float3>.size,
            options: [.cpuCacheModeWriteCombined]
        )
        
        
        let vertexSource = SCNGeometrySource(
            buffer: vertexBuffer1,
            vertexFormat: vertexFormat,
            semantic: SCNGeometrySource.Semantic.vertex,
            vertexCount: pointsList.count,
            dataOffset: 0,
            dataStride: MemoryLayout<vector_float3>.size)
        
        let normalFormat = MTLVertexFormat.float3
        let normalBuffer = device.makeBuffer(
            bytes: normalsList,
            length: normalsList.count * MemoryLayout<vector_float3>.size,
            options: [.cpuCacheModeWriteCombined]
        )
        
        let normalSource = SCNGeometrySource(
            buffer: normalBuffer,
            vertexFormat: normalFormat,
            semantic: SCNGeometrySource.Semantic.normal,
            vertexCount: normalsList.count,
            dataOffset: 0,
            dataStride: MemoryLayout<vector_float3>.size)
        
        
        let uvBuffer = device.makeBuffer(
            bytes: uvList,
            length: normalsList.count * MemoryLayout<vector_float2>.size,
            options: [.cpuCacheModeWriteCombined]
        )
        let uvFormat = MTLVertexFormat.float2
        let uvSource = SCNGeometrySource(
            buffer: uvBuffer,
            vertexFormat: uvFormat,
            semantic: SCNGeometrySource.Semantic.texcoord,
            vertexCount: uvList.count,
            dataOffset: 0,
            dataStride: MemoryLayout<vector_float2>.size)
        
        
        let indexData  = Data(bytes: indexList, count: MemoryLayout<CInt>.size * indexList.count)
        let indexElement = SCNGeometryElement(
            data: indexData,
            primitiveType: SCNGeometryPrimitiveType.triangles,
            primitiveCount: indexList.count/3,
            bytesPerIndex: MemoryLayout<CInt>.size
        )
        
        let geo = SCNGeometry(sources: [vertexSource,normalSource,uvSource], elements: [indexElement])
        
        meshData = MeshData(
            geometry: geo,
            vertexCount: pointsList.count,
            indexList: indexList,
            vertexBuffer1: vertexBuffer1,
            vertexBuffer2: vertexBuffer2,
            normalBuffer: normalBuffer)
    }
    
    
    
}









