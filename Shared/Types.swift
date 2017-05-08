//
//  Types.swift
//  TerrainShader
//
//  Created by Jacob Martin on 5/6/17.
//  Copyright © 2017 Jacob Martin. All rights reserved.
//

import Foundation


#if os(OSX)
    import Cocoa
    
    public typealias Color = NSColor
    public typealias Image = NSImage
#else
    import UIKit
    
    
    
    public typealias Color = UIColor
    public typealias Image = UIImage
#endif
