//
//  Rotations.swift
//  SKLinearAlgebra
//
//  Created by Cameron Little on 3/23/15.
//  Copyright (c) 2015 Cameron Little. All rights reserved.
//

import Foundation
import SceneKit
import GLKit

// Quaternions:
// rotation described by a vector and a rotation.

extension SCNQuaternion {
    public func reverse() -> SCNQuaternion {
        var result = self
        result.w = -result.w
        return result
    }
    
//    public func slerp(_ to: SCNQuaternion, _ t:FloatType) -> SCNQuaternion {
//        let fromQuat = GLKQuaternionMake(self.x, self.y, self.z, self.w)
//        let toQuat = GLKQuaternionMake(to.x, to.y, to.z, to.w)
//        let nQuat = GLKQuaternionSlerp(fromQuat, toQuat, t)
//        return SCNQuaternion(x: nQuat.x, y:nQuat.y, z:nQuat.z, w:nQuat.w)
//    }
}


public func GLKQuaternionMake(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat, _ w: CGFloat) -> GLKQuaternion {
    return GLKQuaternionMake(Float(x), Float(y), Float(z), Float(w))
}

public func GLKQuaternionSlerp(_ quaternionStart: GLKQuaternion, _ quaternionEnd: GLKQuaternion, _ t: CGFloat) -> GLKQuaternion {
    return GLKQuaternionSlerp(quaternionStart, quaternionEnd, t)
}
