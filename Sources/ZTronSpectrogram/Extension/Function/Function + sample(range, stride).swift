import Foundation

public extension Function where Domain: BinaryFloatingPoint {
    /// This function takes samples of `f` in the interval `[a, b]` with a step of `stride`. It is required that `b-a <= stride`.
    ///
    /// - Parameter range: A closed range representing the interval where to evaluate the function.
    /// - Parameter stride: The function will be evaluated at regular intervals (along the domain), in a way that the distance between two .
    /// - Returns: An array whose value at index `i` is computes as `f(a+i*stride)`. The size of such array will be `floor((b-a) / stride) + 1`.
    ///
    /// - Note: If `b-a` is an exact multiple of `stride`, as in `∃ n ∈ ℕ | b-a = n*stride`, then `f(b)`
    /// will be the last element of the returned array, else the last element will be `f(a + (floor((b-a) / stride) + 1) * stride)`.
    ///
    /// - Complexity: Time: O(floor((b-a) / stride) + 1), space: O(floor((b-a) / stride) + 1)
    final func sample(
        range: ClosedRange<Domain>,
        stride: Domain
    ) -> [Codomain] {
        assert(stride < range.upperBound - range.lowerBound)
        let sizeOfOutput: Int = Int(floor((range.upperBound - range.lowerBound) / stride)) + 1
        
        var samples: [Codomain] = []
        samples.reserveCapacity(sizeOfOutput)
        
        for i in 0..<sizeOfOutput {
            let x = range.lowerBound + stride * Domain(i)
            samples.append(self.at(x: x))
        }
        
        return samples
    }
    
    
    /// This function takes `samples` of the function on the interval `[a, b]`. The function is repeatedly evaluated
    /// at approximately equispaced sub-intervals of size `(b-a)/(samples - 1)`
    ///
    /// - Parameter range: A closed range representing the interval where to evaluate the function.
    /// - Parameter samples: The number of samples of the function in the result .
    /// - Returns: An array whose value at index `i` is computes as `f(a+i*(b - a) / (samples - 1))`. The size of such array will be `samples`.
    ///
    /// - Complexity: time: O(samples), memory: O(samples)
    final func sample(
        range: ClosedRange<Domain>,
        taking samples: Int
    ) -> [Codomain] {
        let step = (range.upperBound - range.lowerBound) / Domain(samples - 1)
        var theSamples: [Codomain] = .init()
        theSamples.reserveCapacity(samples)
        
        for i in 0..<samples {
            let nextElement = range.lowerBound + Domain(i) * step
            print(nextElement)
            theSamples.append(self.at(x: nextElement))
        }
        
        return theSamples
    }
}

