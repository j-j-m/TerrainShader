//
//  ShaderGenerator.swift
//  TerrainShader
//
//  Created by Jacob Martin on 5/7/17.
//  Copyright © 2017 Jacob Martin. All rights reserved.
//

import Foundation
import SceneKit
import Metal

struct ShaderModifierDescriptor {
    let name: String
    let includes: [String]?
    
    init(_ name: String, includes:[String]? = nil) {
        self.name = name
        self.includes = includes
    }
}

struct ShaderGenerator {
    let descriptors: [SCNShaderModifierEntryPoint : ShaderModifierDescriptor]
    var modifiers: [SCNShaderModifierEntryPoint:String] = [:]
    
    init(_ descriptors: [SCNShaderModifierEntryPoint : ShaderModifierDescriptor]) {
        
    //init(_ name: String, includes: [String]? = nil) {
        
        self.descriptors = descriptors
        
        for k in descriptors.keys {
            let d = descriptors[k]
            let name = d!.name
            let includes = d?.includes
        
        
        var includeString: String = ""
        
        if let includes = includes {
            for inc in includes {
                if let addition = textForSnippet(named: inc) {
                    includeString += addition + "\n"
                }
                
            }
        }
//        print("includes start")
//        print(includeString)
//        print("includes end")
        
        var modifierString = ""
        
        if let argsString = textForSnippet(named: name+"Args") {
            modifierString += argsString + "\n"
        }
        
        if let bodyString = textForSnippet(named: name+"Body") {
            
            if includeString != "" {
                modifierString +=
                includeString
                + "\n"
            }
            modifierString += bodyString
            
            
            print(modifierString)
            modifiers = [k:modifierString]
        }
        
        }
        
    }
    
    
    
}

func textForSnippet(named s: String) -> String? {
    let bundle = Bundle.main
    if let filepath = bundle.path(forResource: s, ofType: "snip") {
        do {
            let contents = try String(contentsOfFile: filepath)
            return contents
            
        } catch {
            return nil
        }
    } else {
        return nil
    }
}

struct ShaderConstruct {
    
}
