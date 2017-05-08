//
//  Vector3.swift
//  SKLinearAlgebra
//
//  Created by Cameron Little on 2/24/15.
//  Copyright (c) 2015 Cameron Little. All rights reserved.
//

import Foundation
import SceneKit

extension SCNVector3: Vector {
    public init(_ array: [FloatType]) {
        assert(array.count == 3)

        x = array[0]
        y = array[1]
        z = array[2]
    }

    public func to4(_ w: FloatType) -> SCNVector4 {
        return SCNVector4(x: x, y: y, z: z, w: w)
    }

    public func copy() -> SCNVector3 {
        return SCNVector3(x: x, y: y, z: z)
    }

    public var description: String {
        return "[\(x), \(y), \(z)]"
    }

    subscript(i: Int) -> FloatType {
        assert(0 <= i && i < 3, "Index out of range")
        switch i {
        case 0:
            return x
        case 1:
            return y
        case 2:
            return z
        default:
            fatalError("Index out of range")
        }
    }
    
    public func spherical(_ origin: SCNVector3 = SCNVector3()) -> SCNVector3 {
        let x = self.x - origin.x, y = self.y - origin.y, z = self.z - origin.z;
        
    
        let r = magnitude(self - origin)
        let t = x > 0 ? atan(y/x) : 0
        let p = r > 0 ? acos(z/r) : 0
        
        return SCNVector3(r,t,p)
    }
}

// Dot product

public func * (left: SCNVector3, right: SCNVector3) -> FloatType {
    return (left.x * right.x + left.y * right.y + left.z * right.z)
}

// Cross product

public func × (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    let x = left.y*right.z - left.z*right.y
    let y = left.z*right.x - left.x*right.z
    let z = left.x*right.y - left.y*right.x

    return SCNVector3(x: x, y: y, z: z)
}

// Equality and equivalence

public func ==(lhs: SCNVector3, rhs: SCNVector3) -> Bool {
    return SCNVector3EqualToVector3(lhs, rhs)
}

public func ~=(lhs: SCNVector3, rhs: SCNVector3) -> Bool {
    return abs(lhs.x - rhs.x) < EPSILON &&
        abs(lhs.y - rhs.y) < EPSILON &&
        abs(lhs.z - rhs.z) < EPSILON
}

public func !~=(lhs: SCNVector3, rhs: SCNVector3) -> Bool {
    return !(lhs ~= rhs)
}

// Scalar multiplication

public func *(left: SCNVector3, right: FloatType) -> SCNVector3 {
    let x = left.x * right
    let y = left.y * right
    let z = left.z * right

    return SCNVector3(x: x, y: y, z: z)
}

public func *(left: FloatType, right: SCNVector3) -> SCNVector3 {
    let x = right.x * left
    let y = right.y * left
    let z = right.z * left

    return SCNVector3(x: x, y: y, z: z)
}

public func *(left: SCNVector3, right: Int) -> SCNVector3 {
    return left * FloatType(right)
}

public func *(left: Int, right: SCNVector3) -> SCNVector3 {
    return FloatType(left) * right
}

public func *=(left: inout SCNVector3, right: FloatType) {
    left = left * right
}

public func *=(left: inout SCNVector3, right: Int) {
    left = left * right
}

// Scalar Division

public func /(left: SCNVector3, right: FloatType) -> SCNVector3 {
    let x = left.x / right
    let y = left.y / right
    let z = left.z / right

    return SCNVector3(x: x, y: y, z: z)
}

public func /(left: SCNVector3, right: Int) -> SCNVector3 {
    return left / FloatType(right)
}

public func /=(left: inout SCNVector3, right: FloatType) {
    left = left / right
}

public func /=(left: inout SCNVector3, right: Int) {
    left = left / right
}

// Vector subtraction

public func -(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    let x = left.x - right.x
    let y = left.y - right.y
    let z = left.z - right.z

    return SCNVector3(x: x, y: y, z: z)
}

public func -=(left: inout SCNVector3, right: SCNVector3) {
    left = left - right
}

// Vector addition

public func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    let x = left.x + right.x
    let y = left.y + right.y
    let z = left.z + right.z

    return SCNVector3(x: x, y: y, z: z)
}

public func +=(left: inout SCNVector3, right: SCNVector3) {
    left = left + right
}
