//
//  CustomCamera.swift
//  TerrainShader
//
//  Created by Jacob Martin on 5/8/17.
//  Copyright © 2017 Jacob Martin. All rights reserved.
//

import Foundation
import SceneKit

class CustomCamera : SCNCamera {
    override init(){
        super.init()
       
        self.zFar = 1000000
        self.wantsHDR = true
       // self.wantsExposureAdaptation = true
        self.bloomIntensity = 2.511
        self.bloomThreshold = 0.2711
        self.bloomBlurRadius = 1.199
        
        self.averageGray = 0.1954
        
//        self.focalDistance = 2000.0
//        self.focalBlurRadius = 9.3974
//        self.focalSize = 1759.303
//        self.aperture = 0.75
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
