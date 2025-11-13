import Accelerate

public protocol EigenvectorRepresentable {}
extension Array: EigenvectorRepresentable where Element == Double {}
extension DSPDoubleSplitComplex: EigenvectorRepresentable {}
