import Foundation
import Accelerate

public final class RealToRealFunction<Domain: BinaryFloatingPoint> : Sendable {
    typealias Codomain = Domain
    
    private let evaluate: (Domain) -> Codomain
    
    public init(evaluate: @escaping (BinaryFloatingPoint) -> Double) {
        self.evaluate = evaluate
    }
    
    public final func at(x: Domain) -> Codomain {
        return self.evaluate(x)
    }
}



public final func ComplexFunction : Sendable {
    private let evaluate(DSPComplex) -> DSPComplex
    
    public init(evaluate: @escaping (DSPComplex) -> DSPComplex) {
        self.evaluate = evaluate
    }
}
