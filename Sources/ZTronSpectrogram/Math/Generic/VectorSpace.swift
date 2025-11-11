import Foundation

public protocol VectoriSpace {
    static func * (lhs: Self, rhs: any BinaryFloatingPoint) -> Self
    static func * (lhs: any BinaryFloatingPoint, rhs: Self) -> Self
}
