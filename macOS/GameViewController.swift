//
//  GameViewController.swift
//  macOS
//
//  Created by Jacob Martin on 5/5/17.
//  Copyright © 2017 Jacob Martin. All rights reserved.
//

import Cocoa
import SceneKit
import GameplayKit

class GameViewController: NSViewController {

    @IBOutlet var sceneView: SCNView!
    var terrainGenerator: TerrainGenerator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.showsStatistics = true
        
        var scene = TerrestrialScene()
        terrainGenerator = TerrainGenerator(scene: scene)
       
       
        sceneView.backgroundColor = .black
     //   sceneView.allowsCameraControl = true
        sceneView.isPlaying = true
        sceneView.scene = scene
        
    }

}

