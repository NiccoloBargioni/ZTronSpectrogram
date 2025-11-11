import Accelerate

extension DSPDoubleComplex: AlgebraicField {
    public static func / (lhs: DSPDoubleComplex, rhs: DSPDoubleComplex) -> DSPDoubleComplex {
        return (lhs * rhs.conjugate()) * ( 1.0 / (rhs.magnitude * rhs.magnitude) )
    }
    
    public static func /= (lhs: inout DSPDoubleComplex, rhs: DSPDoubleComplex) {
        let rhsNorm2 = rhs.magnitude * rhs.magnitude
        let lhsReal = lhs.real
        
        lhs.real = (lhs.real * rhs.real + lhs.imag * rhs.imag) / rhsNorm2
        lhs.imag = (-1*lhsReal * rhs.imag + lhs.imag * rhs.real) / rhsNorm2
    }
}


