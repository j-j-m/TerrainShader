//
//  TerrainGenerator.swift
//  TerrainShader
//
//  Created by Jacob Martin on 5/6/17.
//  Copyright © 2017 Jacob Martin. All rights reserved.
//

import Foundation
import SceneKit

class TerrainGenerator {
    
    let width: Float = 5000
    let length: Float = 5000

    let shaderDescriptors = [SCNShaderModifierEntryPoint.surface: ShaderModifierDescriptor("terrainSurface", includes: ["simplex2D"])]
    let shaderGenerator:ShaderGenerator
    let mat = SCNMaterial()
    
    init(scene: SCNScene) {
     
        
        shaderGenerator = ShaderGenerator(shaderDescriptors)
        
        shade(mat)
   
        
        let device = MTLCreateSystemDefaultDevice()!
        let deformer = MeshProcessor(device: device)
        
        let range = (-5...5)
        
        for i in range {
            for j in range {
                
                let pos = SCNVector3(FloatType(i) * FloatType(width), 1, FloatType(j) * FloatType(length))
                let terrainNode = generateTile(with: pos, deformer: deformer)
                scene.rootNode.addChildNode(terrainNode)
                

                
            }
        }
        
    }
    
    
    func generateTile(with position: SCNVector3, deformer: MeshProcessor) -> SCNNode {
        
        let tile = Plane(width: width, length: length, step: 100)
        let tileMed = Plane(width: width, length: length, step: 200)
        let tileLow = Plane(width: width, length: length, step: 1000)
        
        for tile in [tile,tileMed,tileLow] {
            let shaderData = ShaderData(location:SCNVector3ToFloat3(position))
            deformer.compute(tile.meshData, data: shaderData)
            
            
        }
        
        let geo = tile.meshData.geometry
        if let mat = geo.firstMaterial {
            shade(mat)
        }
        let geoMed = tileMed.meshData.geometry
        if let mat = geoMed.firstMaterial {
            shade(mat)
        }

        let geoLow = tileLow.meshData.geometry
        if let mat = geoLow.firstMaterial {
            shade(mat)
        }
        
        
        let mediumDetail = SCNLevelOfDetail(geometry: geoMed, worldSpaceDistance: 15000)
        let lowDetail = SCNLevelOfDetail(geometry: geoLow, worldSpaceDistance: 30000)
        
        geo.levelsOfDetail = [mediumDetail, lowDetail]
        
        let node = SCNNode(geometry: geo)
        node.position = position
        return node
    }
    
    func shade(_ mat: SCNMaterial) {
        
        mat.shaderModifiers = shaderGenerator.modifiers
        
        let rockImage = Image(named: "ground_rock1")!
        let grassImage = Image(named: "ground_grass1")!
        let rockProperty = SCNMaterialProperty(contents: rockImage)
        let grassProperty = SCNMaterialProperty(contents: grassImage)
        // The name you supply here should match the texture parameter name in the fragment shader
        mat.setValue(rockProperty, forKey: "rockTexture")
        mat.setValue(grassProperty, forKey: "grassTexture")
        
        mat.isLitPerPixel = true
        mat.cullMode = .back
    }
}
