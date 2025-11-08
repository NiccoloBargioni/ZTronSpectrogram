import Accelerate

extension DSPComplex: @retroactive Numeric {
    public var magnitude: Float {
        return sqrt(self.real * self.real + self.imag * self.imag)
    }
    
    public init(integerLiteral value: Int) {
        self.init(real: Float(value), imag: 0)
    }
    
    
    public init?<T>(exactly source: T) where T : BinaryInteger {
        self.init(real: Float(source), imag: 0)
    }

    
    public static func == (lhs: DSPComplex, rhs: DSPComplex) -> Bool {
        return lhs.real == rhs.real && lhs.imag == rhs.imag
    }
    
    public static func - (lhs: DSPComplex, rhs: DSPComplex) -> DSPComplex {
        return DSPComplex(real: lhs.real - rhs.real, imag: lhs.imag - rhs.imag)
    }
    
    
    public static func + (lhs: DSPComplex, rhs: DSPComplex) -> DSPComplex {
        return DSPComplex(real: lhs.real + rhs.real, imag: lhs.imag + rhs.imag)
    }

    
    public static func *= (lhs: inout DSPComplex, rhs: DSPComplex) {
        let lhsReal: Float = lhs.real
        
        lhs.real = lhs.real * rhs.real - lhs.imag * rhs.imag
        lhs.imag = lhsReal * rhs.imag + lhs.imag * rhs.real
    }
    
    public static func * (lhs: DSPComplex, rhs: DSPComplex) -> DSPComplex {
        return DSPComplex(
            real: lhs.real * rhs.real - lhs.imag * rhs.imag,
            imag: lhs.real * rhs.imag + lhs.imag * rhs.real
        )
    }
}

