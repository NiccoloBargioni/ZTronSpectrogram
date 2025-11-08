import Accelerate

public extension DSPDoubleComplex {
    func conjugate() -> DSPDoubleComplex {
        return .init(real: self.real, imag: -self.imag)
    }
}
