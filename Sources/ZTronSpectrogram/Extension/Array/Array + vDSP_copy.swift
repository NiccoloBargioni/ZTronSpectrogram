import Accelerate

public extension Array where Element == Double {
    func vDSP_copy() -> Self {
        let count = self.count
        
        return self.withUnsafeBufferPointer { sourceBuffer in
            let copied = Array<Double>(unsafeUninitializedCapacity: count) { destBuffer, initializedCount in
                vDSP_mmovD(
                    sourceBuffer.baseAddress!,
                    destBuffer.baseAddress!,
                    vDSP_Length(count),
                    1,
                    1,
                    1
                )
                
                initializedCount = count
            }
            
            return copied
        }
    }
}


public extension Array where Element == Float {
    func vDSP_copy() -> Self {
        return self.withUnsafeBufferPointer { sourceBuffer in
            let copied = Array<Float>(unsafeUninitializedCapacity: self.count) { destBuffer, initializedCount in
                vDSP_mmov(
                    sourceBuffer.baseAddress!,
                    destBuffer.baseAddress!,
                    vDSP_Length(self.count),
                    1,
                    1,
                    1
                )
                initializedCount = count
            }
            
            return copied
        }
    }
}
