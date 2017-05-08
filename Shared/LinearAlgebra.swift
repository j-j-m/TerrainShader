//
//  LinearAlgebra.swift
//  SKLinearAlgebra
//
//  Created by Cameron Little on 2/23/15.
//  Copyright (c) 2015 Cameron Little. All rights reserved.
//

import Foundation
import SceneKit

let EPSILON: FloatType = 0.00001

public protocol Copyable {
    func copy() -> Self
}

public protocol Comparable {
    func ~=(lhs: Self, rhs: Self) -> Bool
    func !~=(lhs: Self, rhs: Self) -> Bool
}

public protocol Vector: Equatable, CustomStringConvertible, Copyable, Comparable {
    func +(lhs: Self, rhs: Self) -> Self
    func +=(lhs: inout Self, rhs: Self)
    func -(lhs: Self, rhs: Self) -> Self
    func -=(lhs: inout Self, rhs: Self)

    func *(lhs: Self, rhs: Self) -> FloatType

    func *(lhs: FloatType, rhs: Self) -> Self
    func *(lhs: Self, rhs: FloatType) -> Self
    func *=(lhs: inout Self, rhs: FloatType)
    func *(lhs: Int, rhs: Self) -> Self
    func *(lhs: Self, rhs: Int) -> Self
    func *=(lhs: inout Self, rhs: Int)

    func /(lhs: Self, rhs: FloatType) -> Self
    func /=(lhs: inout Self, rhs: FloatType)
    func /(lhs: Self, rhs: Int) -> Self
    func /=(lhs: inout Self, rhs: Int)

    func ×(lhs: Self, rhs: Self) -> Self
}

public protocol Matrix: Equatable, CustomStringConvertible, Copyable, Comparable {
    func *(lhs: FloatType, rhs: Self) -> Self
    func *(lhs: Self, rhs: FloatType) -> Self
    func *=(lhs: inout Self, rhs: FloatType)
    func *(lhs: Int, rhs: Self) -> Self
    func *(lhs: Self, rhs: Int) -> Self
    func *=(lhs: inout Self, rhs: Int)

    func /(lhs: Self, rhs: FloatType) -> Self
    func /=(lhs: inout Self, rhs: FloatType)
    func /(lhs: Self, rhs: Int) -> Self
    func /=(lhs: inout Self, rhs: Int)
}

infix operator × // Cross product

infix operator ~= // Equivalent

infix operator !~= // Not equivalent

public func cross<T:Vector> (_ a: T, b: T) -> T {
    return a × b
}

public func magnitude<T: Vector> (_ vec: T) -> FloatType {
    return sqrt(vec * vec)
}

public func normalize<T: Vector> (_ vec: T) -> T {
    let vmag = magnitude(vec)
    if vmag == 0 {
        return vec / 1
    }
    return vec / vmag
}

public func angle<T:Vector> (_ left: T, _ right: T) -> FloatType? {
    let ml = magnitude(left)
    let mr = magnitude(right)
    if ml == 0 || mr == 0 {
        return nil
    }
    return acos((left * right) / (ml * mr))
}

/* comp_{b} a
 * result is the length of vector a on vector b
 *
 *              b
 *              |
 *              |
 *            { |   / a
 * comp(a, b) { |  /
 *            { | /
 *
 */
public func component<T:Vector> (_ a: T, b: T) -> FloatType {
    let bmag = magnitude(b)
    if bmag == 0 {
        fatalError("Zero vector provided to component")
    }
    return (a * b) / bmag
}

/* proj_{b} a 
 */
public func projection<T:Vector> (_ a: T, b: T) -> T {
    let magb = magnitude(b)
    if magb == 0 {
        fatalError("Zero vector provided to projection")
    }
    let adotb = a * b
    return (adotb / pow(magb, 2)) * b
}
