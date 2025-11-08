import Accelerate

extension DSPDoubleComplex: @retroactive Numeric {
    public var magnitude: Double {
        return sqrtl(self.real * self.real + self.imag * self.imag)
    }
    
    public init(integerLiteral value: Int) {
        self.init(real: Double(value), imag: 0)
    }
    
    
    public init?<T>(exactly source: T) where T : BinaryInteger {
        self.init(real: Double(source), imag: 0)
    }

    
    public static func == (lhs: DSPDoubleComplex, rhs: DSPDoubleComplex) -> Bool {
        return lhs.real == rhs.real && lhs.imag == rhs.imag
    }
    
    public static func - (lhs: DSPDoubleComplex, rhs: DSPDoubleComplex) -> DSPDoubleComplex {
        return DSPDoubleComplex(real: lhs.real - rhs.real, imag: lhs.imag - rhs.imag)
    }
    
    
    public static func + (lhs: DSPDoubleComplex, rhs: DSPDoubleComplex) -> DSPDoubleComplex {
        return DSPDoubleComplex(real: lhs.real + rhs.real, imag: lhs.imag + rhs.imag)
    }

    
    public static func *= (lhs: inout DSPDoubleComplex, rhs: DSPDoubleComplex) {
        let lhsReal: Double = lhs.real
        
        lhs.real = lhs.real * rhs.real - lhs.imag * rhs.imag
        lhs.imag = lhsReal * rhs.imag + lhs.imag * rhs.real
    }
    
    public static func * (lhs: DSPDoubleComplex, rhs: DSPDoubleComplex) -> DSPDoubleComplex {
        return DSPDoubleComplex(
            real: lhs.real * rhs.real - lhs.imag * rhs.imag,
            imag: lhs.real * rhs.imag + lhs.imag * rhs.real
        )
    }
}

