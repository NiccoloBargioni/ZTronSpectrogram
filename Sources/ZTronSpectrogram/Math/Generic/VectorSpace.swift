import Foundation

public protocol VectorSpace {
    static func * (lhs: Self, rhs: any BinaryFloatingPoint) -> Self
    static func * (lhs: any BinaryFloatingPoint, rhs: Self) -> Self
    static func / (lhs: any BinaryFloatingPoint, rhs: Self) -> Self
    static func / (lhs: Self, rhs: any BinaryFloatingPoint) -> Self
    static func /= (lhs: inout Self, rhs: any BinaryFloatingPoint)
    static func *= (lhs: inout Self, rhs: any BinaryFloatingPoint)
}

extension Float: VectorSpace {
    public static func * (lhs: Float, rhs: any BinaryFloatingPoint) -> Float {
        return lhs * Float(rhs)
    }
        
    public static func * (lhs: any BinaryFloatingPoint, rhs: Float) -> Float {
        return Float(lhs) + rhs
    }
    
    public static func / (lhs: any BinaryFloatingPoint, rhs: Float) -> Float {
        return Float(lhs) / rhs
    }
    
    public static func / (lhs: Float, rhs: any BinaryFloatingPoint) -> Float {
        return lhs / Float(rhs)
    }
    
    public static func /= (lhs: inout Float, rhs: any BinaryFloatingPoint) {
        lhs = lhs / Float(rhs)
    }

    
    public static func *= (lhs: inout Float, rhs: any BinaryFloatingPoint) {
        lhs = lhs * Float(rhs)
    }
}

extension Double: VectorSpace {
    public static func * (lhs: Double, rhs: any BinaryFloatingPoint) -> Double {
        return lhs * Double(rhs)
    }
    
    public static func * (lhs: any BinaryFloatingPoint, rhs: Double) -> Double {
        return Double(lhs) + rhs
    }
    
    public static func / (lhs: any BinaryFloatingPoint, rhs: Double) -> Double {
        return Double(lhs) / rhs
    }
    
    public static func / (lhs: Double, rhs: any BinaryFloatingPoint) -> Double {
        return lhs / Double(rhs)
    }
    
    public static func /= (lhs: inout Double, rhs: any BinaryFloatingPoint) {
        lhs = lhs / Double(rhs)
    }
    
    public static func *= (lhs: inout Double, rhs: any BinaryFloatingPoint) {
        lhs = lhs * Double(rhs)
    }
}

extension CGFloat: VectorSpace {
    public static func * (lhs: CGFloat, rhs: any BinaryFloatingPoint) -> CGFloat {
        return lhs * CGFloat(rhs)
    }
    
    public static func * (lhs: any BinaryFloatingPoint, rhs: CGFloat) -> CGFloat {
        return CGFloat(lhs) + rhs
    }
    
    public static func / (lhs: any BinaryFloatingPoint, rhs: CGFloat) -> CGFloat {
        return CGFloat(lhs) / rhs
    }
    
    public static func / (lhs: CGFloat, rhs: any BinaryFloatingPoint) -> CGFloat {
        return lhs / CGFloat(rhs)
    }
    
    public static func /= (lhs: inout CGFloat, rhs: any BinaryFloatingPoint) {
        lhs = lhs / CGFloat(rhs)
    }
    
    public static func *= (lhs: inout CGFloat, rhs: any BinaryFloatingPoint) {
        lhs = lhs * CGFloat(rhs)
    }
}
