//
//  Matrix4.swift
//  SKLinearAlgebra
//
//  Created by Cameron Little on 2/24/15.
//  Copyright (c) 2015 Cameron Little. All rights reserved.
//

import Accelerate
import Foundation
import SceneKit

extension SCNMatrix4: Matrix {
    public init(_ contents: [[FloatType]]) {
        assert(contents.count == 4 && contents[0].count == 4)

        self.init(x: SCNVector4(contents[0]),
            y: SCNVector4(contents[1]),
            z: SCNVector4(contents[2]),
            w: SCNVector4(contents[3]))
    }

    public init(_ a: [FloatType]) {
        assert(a.count == 16)

        m11 = a[0]
        m12 = a[1]
        m13 = a[2]
        m14 = a[3]

        m21 = a[4]
        m22 = a[5]
        m23 = a[6]
        m24 = a[7]

        m31 = a[8]
        m32 = a[9]
        m33 = a[10]
        m34 = a[11]

        m41 = a[12]
        m42 = a[13]
        m43 = a[14]
        m44 = a[15]
    }

    public init(x: SCNVector4, y: SCNVector4, z: SCNVector4, w: SCNVector4) {
        m11 = x.x
        m12 = x.y
        m13 = x.z
        m14 = x.w

        m21 = y.x
        m22 = y.y
        m23 = y.z
        m24 = y.w

        m31 = z.x
        m32 = z.y
        m33 = z.z
        m34 = z.w

        m41 = w.x
        m42 = w.y
        m43 = w.z
        m44 = w.w
    }

    public func copy() -> SCNMatrix4 {
        return SCNMatrix4(m11: m11, m12: m12, m13: m13, m14: m14, m21: m21, m22: m22, m23: m23, m24: m24, m31: m31, m32: m32, m33: m33, m34: m34, m41: m41, m42: m42, m43: m43, m44: m44)
    }

    subscript(row: Int, col: Int) -> FloatType {
        get {
            assert((0 <= row && row < 4) && (0 <= col && col < 4), "Index out of range")
            switch row {
            case 0:
                switch col {
                case 0:
                    return m11
                case 1:
                    return m21
                case 2:
                    return m31
                case 3:
                    return m41
                default:
                    fatalError("Index out of range")
                }
            case 1:
                switch col {
                case 0:
                    return m12
                case 1:
                    return m22
                case 2:
                    return m32
                case 3:
                    return m42
                default:
                    fatalError("Index out of range")
                }
            case 2:
                switch col {
                case 0:
                    return m13
                case 1:
                    return m23
                case 2:
                    return m33
                case 3:
                    return m43
                default:
                    fatalError("Index out of range")
                }
            case 3:
                switch col {
                case 0:
                    return m14
                case 1:
                    return m24
                case 2:
                    return m34
                case 3:
                    return m44
                default:
                    fatalError("Index out of range")
                }
            default:
                fatalError("Index out of range")
            }
        }
        set {
            assert((0 <= row && row < 4) && (0 <= col && col < 4), "Index out of range")
            switch row {
            case 0:
                switch col {
                case 0:
                    m11 = newValue
                case 1:
                    m12 = newValue
                case 2:
                    m13 = newValue
                case 3:
                    m14 = newValue
                default:
                    fatalError("Index out of range")
                }
            case 1:
                switch col {
                case 0:
                    m21 = newValue
                case 1:
                    m22 = newValue
                case 2:
                    m23 = newValue
                case 3:
                    m24 = newValue
                default:
                    fatalError("Index out of range")
                }
            case 2:
                switch col {
                case 0:
                    m31 = newValue
                case 1:
                    m32 = newValue
                case 2:
                    m33 = newValue
                case 3:
                    m34 = newValue
                default:
                    fatalError("Index out of range")
                }
            case 3:
                switch col {
                case 0:
                    m41 = newValue
                case 1:
                    m42 = newValue
                case 2:
                    m43 = newValue
                case 3:
                    m44 = newValue
                default:
                    fatalError("Index out of range")
                }
            default:
                fatalError("Index out of range")
            }
        }
    }

    public var description: String {
        return "[[\(m11), \(m12), \(m13), \(m14)]\n" +
            " [\(m21), \(m22), \(m23), \(m24)]\n" +
            " [\(m31), \(m32), \(m33), \(m34)]\n" +
            " [\(m41), \(m42), \(m43), \(m44)]]"
    }

    public var FloatTypeArray: [[FloatType]] {
        return [[m11, m12, m13, m14],
            [m21, m22, m23, m24],
            [m31, m32, m33, m34],
            [m41, m42, m43, m44]]
    }

    fileprivate var linearFloatTypeArray: [FloatType] {
        return [m11, m12, m13, m14,
            m21, m22, m23, m24,
            m31, m32, m33, m34,
            m41, m42, m43, m44]
    }
}

public func SCNMatrix4MakeColumns(_ x: SCNVector4, y: SCNVector4, z: SCNVector4, w: SCNVector4) -> SCNMatrix4 {
    return SCNMatrix4(
        m11: x.x, m12: x.y, m13: x.z, m14: x.w,
        m21: y.x, m22: y.y, m23: y.z, m24: y.w,
        m31: z.x, m32: z.y, m33: z.z, m34: z.w,
        m41: w.x, m42: w.y, m43: w.z, m44: w.w)
}

// Equality and equivalence

public func ==(lhs: SCNMatrix4, rhs: SCNMatrix4) -> Bool {
    return SCNMatrix4EqualToMatrix4(lhs, rhs)
}

public func ~=(lhs: SCNMatrix4, rhs: SCNMatrix4) -> Bool {
    let m11 = abs(lhs.m11 - rhs.m11) < EPSILON
    let m12 = abs(lhs.m12 - rhs.m12) < EPSILON
    let m13 = abs(lhs.m13 - rhs.m13) < EPSILON
    let m14 = abs(lhs.m14 - rhs.m14) < EPSILON
    let m21 = abs(lhs.m21 - rhs.m21) < EPSILON
    let m22 = abs(lhs.m22 - rhs.m22) < EPSILON
    let m23 = abs(lhs.m23 - rhs.m23) < EPSILON
    let m24 = abs(lhs.m24 - rhs.m24) < EPSILON
    let m31 = abs(lhs.m31 - rhs.m31) < EPSILON
    let m32 = abs(lhs.m32 - rhs.m32) < EPSILON
    let m33 = abs(lhs.m33 - rhs.m33) < EPSILON
    let m34 = abs(lhs.m34 - rhs.m34) < EPSILON
    let m41 = abs(lhs.m41 - rhs.m41) < EPSILON
    let m42 = abs(lhs.m42 - rhs.m42) < EPSILON
    let m43 = abs(lhs.m43 - rhs.m43) < EPSILON
    let m44 = abs(lhs.m44 - rhs.m44) < EPSILON

    return m11 && m12 && m13 && m14 &&
        m21 && m22 && m23 && m24 &&
        m31 && m32 && m33 && m34 &&
        m41 && m42 && m43 && m44
}

public func !~=(lhs: SCNMatrix4, rhs: SCNMatrix4) -> Bool {
    return !(lhs ~= rhs)
}

// Matrix vector multiplication

public func *(left: SCNMatrix4, right: SCNVector4) -> SCNVector4 {
    let x = left.m11*right.x + left.m21*right.y + left.m31*right.z
    let y = left.m12*right.x + left.m22*right.y + left.m32*right.z
    let z = left.m13*right.x + left.m23*right.y + left.m33*right.z

    return SCNVector4(x: x, y: y, z: z, w: right.w * left.m44)
}

public func *(left: SCNMatrix4, right: SCNVector3) -> SCNVector3 {
    return (left * right.to4(0)).to3()
}

// Scalar multiplication

public func *(left: SCNMatrix4, right: FloatType) -> SCNMatrix4 {
    return SCNMatrix4(
        m11: left.m11 * right, m12: left.m12 * right, m13: left.m13 * right, m14: left.m14 * right,
        m21: left.m21 * right, m22: left.m22 * right, m23: left.m23 * right, m24: left.m24 * right,
        m31: left.m31 * right, m32: left.m32 * right, m33: left.m33 * right, m34: left.m34 * right,
        m41: left.m41 * right, m42: left.m42 * right, m43: left.m43 * right, m44: left.m44 * right)
}

public func *(left: FloatType, right: SCNMatrix4) -> SCNMatrix4 {
    return right * left
}

public func *(left: SCNMatrix4, right: Int) -> SCNMatrix4 {
    return left * FloatType(right)
}

public func *(left: Int, right: SCNMatrix4) -> SCNMatrix4 {
    return right * FloatType(left)
}

public func *=(left: inout SCNMatrix4, right: FloatType) {
    left = left * right
}

public func *=(left: inout SCNMatrix4, right: Int) {
    left = left * right
}

// Scalar division

public func /(left: SCNMatrix4, right: FloatType) -> SCNMatrix4 {
    return SCNMatrix4(
        m11: left.m11 / right, m12: left.m12 / right, m13: left.m13 / right, m14: left.m14 / right,
        m21: left.m21 / right, m22: left.m22 / right, m23: left.m23 / right, m24: left.m24 / right,
        m31: left.m31 / right, m32: left.m32 / right, m33: left.m33 / right, m34: left.m34 / right,
        m41: left.m41 / right, m42: left.m42 / right, m43: left.m43 / right, m44: left.m44 / right)
}

public func /(left: SCNMatrix4, right: Int) -> SCNMatrix4 {
    return left / FloatType(right)
}

public func /=(left: inout SCNMatrix4, right: FloatType) {
    left = left / right
}

public func /=(left: inout SCNMatrix4, right: Int) {
    left = left / right
}

// https://bitbucket.org/eigen/eigen/src/968c30931d04a35c8b02d1bb386e690b45dc275c/Eigen/src/LU/Determinant.h?at=default#cl-75
private func detHelper(_ matrix: SCNMatrix4, j: Int, k: Int, m: Int, n: Int) -> FloatType {
    let a = (matrix[j, 0] * matrix[k, 1] - matrix[k, 0] * matrix[j, 1])
    let b = (matrix[m, 2] * matrix[n, 3] - matrix[n, 2] * matrix[m, 3])
    return a*b
}
public func det(_ m: SCNMatrix4) -> FloatType {
    return detHelper(m, j: 0, k: 1, m: 2, n: 3)
        - detHelper(m, j: 0, k: 2, m: 1, n: 3)
        + detHelper(m, j: 0, k: 3, m: 1, n: 2)
        + detHelper(m, j: 1, k: 2, m: 0, n: 3)
        - detHelper(m, j: 1, k: 3, m: 0, n: 2)
        + detHelper(m, j: 2, k: 3, m: 0, n: 1)
}

public func transpose(_ m: SCNMatrix4) -> SCNMatrix4 {
    return SCNMatrix4(
        m11: m.m11, m12: m.m21, m13: m.m31, m14: m.m41,
        m21: m.m12, m22: m.m22, m23: m.m32, m24: m.m42,
        m31: m.m13, m32: m.m23, m33: m.m33, m34: m.m43,
        m41: m.m14, m42: m.m24, m43: m.m34, m44: m.m44)
}

public func inverse(_ m: SCNMatrix4) -> SCNMatrix4 {
    // https://github.com/mattt/Surge/

    var results = [FloatType](repeating: 0.0, count: 16)

    let grid = m.linearFloatTypeArray

    var ipiv = [__CLPK_integer](repeating: 0, count: 16)
    let lwork = __CLPK_integer(16)
    var work = [FloatType](repeating: 0.0, count: Int(lwork))
    let error: __CLPK_integer = 0
    var nc = __CLPK_integer(4)

//    sgetrf_(&nc, &nc, (grid), &nc, &ipiv, &error)
//    sgetri_(&nc, &(grid), &nc, &ipiv, &work, &lwork, &error)

    assert(error == 0, "MatrixFloatType not invertible")

    return SCNMatrix4(grid)
}
