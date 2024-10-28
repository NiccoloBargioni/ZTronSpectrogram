import Foundation
import Accelerate

internal protocol FFTStrategyDecorator: Sendable {
    func transform(samples: DSPSplitComplex) -> DSPSplitComplex
}
