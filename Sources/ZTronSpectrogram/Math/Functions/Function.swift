import Foundation
import QuartzCore


public final class Function<Domain: Numeric & AdditiveArithmetic, Codomain: Numeric & AdditiveArithmetic> : Sendable {
    private let evaluate: @Sendable (Domain) -> Codomain
    
    public init(evaluate: @escaping @Sendable (Domain) -> Codomain) {
        self.evaluate = evaluate
    }
    
    public final func at(x: Domain) -> Codomain {
        return self.evaluate(x)
    }
}


public extension Function where Domain: BinaryFloatingPoint {
    /// This function takes samples in the interval `[a, b]` with a step of `stride`. It is required that `b-a <= stride`.
    ///
    /// - Parameter range: A closed range representing the interval where to evaluate the function.
    /// - Parameter stride: The function will be evaluated at regular intervals (along the domain), in a way that the distance between two .
    /// - Returns: An array whose value at index `i` is computes as `f(a+i*stride)`. The size of such array will be `ceil(b-a) / stride`.
    ///
    /// - Note: If `b-a` is an exact multiple of `stride`, as in `∃ n ∈ ℕ | b-a = n*stride`, then `f(b)`
    /// will be the last element of the returned array, else the last element will be `f(a + ceil((b-a) / stride) * stride)`.
    final func sample(
        range: ClosedRange<Domain>,
        stride: Domain
    ) -> [Codomain] {
        assert(stride < range.upperBound - range.upperBound)
        let sizeOfOutput: Int = Int(ceil((range.upperBound - range.upperBound) / stride))
        
        var samples: [Codomain] = [self.evaluate(range.lowerBound)]
        samples.reserveCapacity(sizeOfOutput)
        
        var nextExement: Domain = range.lowerBound
        
        while nextExement <= range.upperBound {
            nextExement += stride
            samples.append(self.evaluate(nextExement))
        }
        
        return samples
    }
}

