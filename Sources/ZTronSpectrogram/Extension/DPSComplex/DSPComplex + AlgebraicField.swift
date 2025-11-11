import Accelerate

extension DSPComplex: AlgebraicField {
    public static func / (lhs: DSPComplex, rhs: DSPComplex) -> DSPComplex {
        return (lhs * rhs.conjugate()) * ( 1.0 / (rhs.magnitude * rhs.magnitude) )
    }
    
    public static func /= (lhs: inout DSPComplex, rhs: DSPComplex) {
        let rhsNorm2 = rhs.magnitude * rhs.magnitude
        let lhsReal = lhs.real
        
        lhs.real = (lhs.real * rhs.real + lhs.imag * rhs.imag) / rhsNorm2
        lhs.imag = (-1*lhsReal * rhs.imag + lhs.imag * rhs.real) / rhsNorm2
    }
}


