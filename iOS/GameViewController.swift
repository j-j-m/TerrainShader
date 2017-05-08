//
//  GameViewController.swift
//  TerrainShader
//
//  Created by Jacob Martin on 5/5/17.
//  Copyright © 2017 Jacob Martin. All rights reserved.
//

import UIKit
import SceneKit
import GameplayKit

class GameViewController: UIViewController {

    var terrainGenerator: TerrainGenerator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = TerrestrialScene()
        terrainGenerator = TerrainGenerator(scene: scene)
        
        // Present the scene
        let sceneView = self.view as! SCNView
        sceneView.showsStatistics = true
        sceneView.backgroundColor = .black
        sceneView.isPlaying = true
        sceneView.scene = scene
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
}
