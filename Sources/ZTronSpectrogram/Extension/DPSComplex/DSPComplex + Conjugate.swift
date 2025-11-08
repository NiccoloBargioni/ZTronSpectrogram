import Accelerate

public extension DSPComplex {
    func conjugate() -> DSPComplex {
        return .init(real: self.real, imag: -self.imag)
    }
}
