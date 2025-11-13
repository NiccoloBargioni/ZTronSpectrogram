import Accelerate

extension DSPDoubleComplex: VectorSpace {
    public static func * (lhs: any BinaryFloatingPoint, rhs: DSPDoubleComplex) -> DSPDoubleComplex {
        return DSPDoubleComplex(real: rhs.real * lhs, imag: rhs.imag * lhs)
    }
    
    public static func * (lhs: DSPDoubleComplex, rhs: any BinaryFloatingPoint) -> DSPDoubleComplex {
        return DSPDoubleComplex(real: lhs.real * rhs, imag: lhs.imag * rhs)
    }
    
    public static func / (lhs: any BinaryFloatingPoint, rhs: DSPDoubleComplex) -> DSPDoubleComplex {
        let complexLHS = DSPDoubleComplex(real: Double(lhs), imag: .zero)
        return complexLHS / rhs
    }

    public static func / (lhs: DSPDoubleComplex, rhs: any BinaryFloatingPoint) -> DSPDoubleComplex {
        let rhsAsFloat = Float(rhs)
        return DSPDoubleComplex(real: lhs.real / rhsAsFloat, imag: lhs.imag / rhsAsFloat)
    }
    
    public static func /= (lhs: inout DSPDoubleComplex, rhs: any BinaryFloatingPoint) {
        let rhsAsFloat = Float(rhs)
        lhs.real = lhs.real / rhsAsFloat
        lhs.imag = lhs.imag / rhsAsFloat
    }
    
    public static func *= (lhs: inout DSPDoubleComplex, rhs: any BinaryFloatingPoint) {
        lhs.real = lhs.real * rhs
        lhs.imag = lhs.imag * rhs
    }
}
