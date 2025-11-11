import Foundation

public protocol AlgebraicField {
    static func / (lhs: Self, rhs: Self) -> Self
    static func /= (lhs: inout Self, rhs: Self)
}


extension Float: AlgebraicField { }
extension Double: AlgebraicField { }
extension CGFloat: AlgebraicField {  }
