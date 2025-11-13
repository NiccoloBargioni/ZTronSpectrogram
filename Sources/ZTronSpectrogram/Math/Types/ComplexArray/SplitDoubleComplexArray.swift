import Accelerate

public final class SplitDoubleComplexArray: CustomStringConvertible {
    public var description: String {
        return self.toString()
    }
    
    private var array: DSPDoubleSplitComplex
    private let size: Int
    
    public var count: Int {
        return self.size
    }
    
    public init(array: DSPDoubleSplitComplex, size: Int) {
        self.array = array
        self.size = size
    }
    
    subscript(index: Int) -> DSPDoubleComplex {
        return DSPDoubleComplex(
            real: self.array.realp[index],
            imag: self.array.imagp[index]
        )
    }
    
    
    subscript(range: Range<Int>) -> DSPDoubleSplitComplex {
          get {
              return DSPDoubleSplitComplex(
                  realp: self.array.realp.advanced(by: range.lowerBound),
                  imagp: self.array.imagp.advanced(by: range.lowerBound)
              )
          }
      }
    
    subscript(range: ClosedRange<Int>) -> DSPDoubleSplitComplex {
        get {
            return DSPDoubleSplitComplex(
                realp: self.array.realp.advanced(by: range.lowerBound),
                imagp: self.array.imagp.advanced(by: range.lowerBound)
            )
        }
    }
    
    subscript(range: PartialRangeFrom<Int>) -> DSPDoubleSplitComplex {
        get {
            return DSPDoubleSplitComplex(
                realp: self.array.realp.advanced(by: range.lowerBound),
                imagp: self.array.imagp.advanced(by: range.lowerBound)
            )
        }
    }

    
    internal final func takeSamples(stride: Int, initialOffset: Int) -> SplitDoubleComplexArray {
        let outputSamplesCount = Int(floor(Double(self.size - initialOffset) / Double(stride))) + 1
        
        let realBuffer = UnsafeMutablePointer<Double>.allocate(capacity: outputSamplesCount)
        let imagBuffer = UnsafeMutablePointer<Double>.allocate(capacity: outputSamplesCount)
        
        var sourceComplex = DSPDoubleSplitComplex(
            realp: self.array.realp.advanced(by: initialOffset),
            imagp: self.array.imagp.advanced(by: initialOffset)
        )

        var destComplex = DSPDoubleSplitComplex(realp: realBuffer, imagp: imagBuffer)
        
        
        vDSP_zvmovD(
            &sourceComplex,
            vDSP_Stride(stride),
            &destComplex,
            vDSP_Stride(1),
            vDSP_Length(outputSamplesCount)
        )
        
        return SplitDoubleComplexArray(array: destComplex, size: outputSamplesCount)
    }
    
    private final func toString() -> String {
        var description = "[ "
        
        for i in 0..<self.size {
            description += self[i].description
            
            if i < self.size - 1 {
                description += ", "
            } else {
                description += " ]"
            }
        }
        
        return description
    }
}
