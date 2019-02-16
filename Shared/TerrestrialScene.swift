//
//  TerrestrialScene.swift
//  TerrainShader
//
//  Created by Jacob Martin on 5/5/17.
//  Copyright © 2017 Jacob Martin. All rights reserved.
//

import Foundation
import SceneKit
import ModelIO

class TerrestrialScene: SCNScene {
    
    var sky = MDLSkyCubeTexture(name: nil,
                                channelEncoding: MDLTextureChannelEncoding.uInt8,
                                textureDimensions: [Int32(160), Int32(160)],
                                turbidity: 0.2,
                                sunElevation: 0.3,
                                upperAtmosphereScattering: 0.8,
                                groundAlbedo: 0.7)

    
    override init()
    {
        super.init()
        
        setupEnvironment()
        setupObjects()
        
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }

    
    func setupEnvironment(){
        sky.groundColor = Color.cyan.cgColor
        sky.update()
        
        self.fogStartDistance = 5000
        self.fogEndDistance = 40000
        self.fogDensityExponent = 2.0
        self.fogColor = Color(cgColor: sky.groundColor!)
        
        
        let light = SCNLight()
        light.type = .omni
        light.zFar = 1000000
        if #available(OSX 10.13, *) {
            light.forcesBackFaceCasters = true
        } 
        light.castsShadow = true
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(100000, 100000, 100000)
        self.rootNode.addChildNode(lightNode)
        
        let floor = SCNFloor()
        floor.reflectivity = 0.0
        floor.firstMaterial?.diffuse.contents = Color(red: 0.0, green: 0.0, blue: 0.3, alpha: 1.0)
        floor.firstMaterial?.reflective.contents = self.sky.imageFromTexture()?.takeUnretainedValue()
        self.rootNode.addChildNode(SCNNode(geometry:floor))
        
        self.background.contents = self.sky.imageFromTexture()?.takeUnretainedValue()
    }
    
    
    func setupObjects() {
        let center = SCNNode()
        
        
        
        let camera = SCNNode()
        let cam = CustomCamera()

        camera.camera = cam
        camera.transform = SCNMatrix4MakeTranslation(10000, 2600, 10000)
        
        let orbital = SCNNode()
        orbital.addChildNode(camera)
        
        let lookAtSphere = SCNLookAtConstraint(target: center)
        lookAtSphere.isGimbalLockEnabled = true
        camera.constraints = [lookAtSphere]
        
        
        self.rootNode.addChildNode(center)
        self.rootNode.addChildNode(orbital)
        
        let rotationAction = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat.pi/2, z: 0, duration: 100))
        orbital.runAction(rotationAction)

        
    }
    
    
    
    
}
