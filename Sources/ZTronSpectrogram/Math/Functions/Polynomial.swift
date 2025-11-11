import Accelerate
import Foundation

@available(iOS 15.0, *)
public final class Polynomial<
    Domain:
        Numeric
        & VectorSpace
        & AdditiveArithmetic & Sendable
>: Function<Domain, Domain> {

    private let coefficients: [Double]
    private let roots: [DSPDoubleComplex]

    /// Initializes the polynomial with the specified coefficients. From left to right, the coefficients are assigned to the highest to lowest degree.
    ///
    /// For example: `init<DSPComplex>(1,2,3,4,5)` creates a representation of `x^4 + 2x^3 + 3x^2 + 4x + 5`.
    public init(
        coefficients: Double...
    ) {
        let firstNonNilCoefficientIndex = coefficients.firstIndex { coefficient in
            return coefficient != 0
        }
        
        self.coefficients =
            (firstNonNilCoefficientIndex == nil || firstNonNilCoefficientIndex ?? 0 > 0) ?
                coefficients
                    :
            Array<Double>(coefficients.prefix(firstNonNilCoefficientIndex! + 1))
            
        
        self.roots = []

        super.init { x in
            let complexOne = Domain(exactly: 1)!
            var output: Domain = complexOne * coefficients[0]

            for i in 1..<coefficients.count {
                output = output * x + (complexOne * coefficients[i])
            }

            return output
        }
    }
}
