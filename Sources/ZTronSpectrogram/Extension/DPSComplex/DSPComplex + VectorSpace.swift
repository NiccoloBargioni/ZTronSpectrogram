import Accelerate

extension DSPComplex: VectorSpace {
    public static func * (lhs: any BinaryFloatingPoint, rhs: DSPComplex) -> DSPComplex {
        return DSPComplex(real: rhs.real * lhs, imag: rhs.imag * lhs)
    }
    
    public static func * (lhs: DSPComplex, rhs: any BinaryFloatingPoint) -> DSPComplex {
        return DSPComplex(real: lhs.real * rhs, imag: lhs.imag * rhs)
    }
    
    public static func / (lhs: any BinaryFloatingPoint, rhs: DSPComplex) -> DSPComplex {
        let complexLHS = DSPComplex(real: Float(lhs), imag: .zero)
        return complexLHS / rhs
    }
    
    public static func / (lhs: DSPComplex, rhs: any BinaryFloatingPoint) -> DSPComplex {
        let rhsAsFloat = Float(rhs)
        return DSPComplex(real: lhs.real / rhsAsFloat, imag: lhs.imag / rhsAsFloat)
    }
    
    public static func /= (lhs: inout DSPComplex, rhs: any BinaryFloatingPoint) {
        let rhsAsFloat = Float(rhs)
        lhs.real = lhs.real / rhsAsFloat
        lhs.imag = lhs.imag / rhsAsFloat
    }
    
    public static func *= (lhs: inout DSPComplex, rhs: any BinaryFloatingPoint) {
        lhs.real = lhs.real * rhs
        lhs.imag = lhs.imag * rhs
    }
}
