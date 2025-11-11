import Foundation
import QuartzCore


public class Function<Domain: Numeric & AdditiveArithmetic, Codomain: Numeric & AdditiveArithmetic> {
    private let evaluate: @Sendable (Domain) -> Codomain
    
    public init(evaluate: @escaping @Sendable (Domain) -> Codomain) {
        self.evaluate = evaluate
    }
    
    public final func at(x: Domain) -> Codomain {
        return self.evaluate(x)
    }
}

