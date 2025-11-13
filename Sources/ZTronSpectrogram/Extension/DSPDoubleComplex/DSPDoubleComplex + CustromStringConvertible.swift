import Accelerate

extension DSPDoubleComplex: @retroactive CustomStringConvertible {
    public var description: String {
        let realValue = self.real
        let imagValue = self.imag
        
        if abs(imagValue) < 1e-10 {
            return String(format: "%.3f + i0", realValue)
        } else if abs(realValue) < 1e-10 {
            return String(format: "0 %.3fi", imagValue)
        } else {
            let sign = imagValue >= 0 ? "+" : "-"
            return String(format: "%.3f", realValue) + " \(sign) " + String(format: "i%.3f", abs(imagValue))
        }
    }
}
