import Accelerate
import QuartzCore


public final class ComplexToComplexFunction : Sendable {
    private let evaluate: @Sendable (DSPComplex) -> DSPComplex
    
    public init(evaluate: @escaping @Sendable (DSPComplex) -> DSPComplex) {
        self.evaluate = evaluate
    }
    
    public final func at(x: DSPComplex) -> DSPComplex {
        return self.evaluate(x)
    }
    
    public final func sample() {
        let a: DSPComplex = .init(real: 1, imag: 0)
        let b: DSPComplex = .init(real: 1, imag: 0)
        
        print(a*b)
    }
}

