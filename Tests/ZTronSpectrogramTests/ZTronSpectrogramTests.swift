import Testing
import Foundation
import Accelerate

import Combine
@testable import ZTronSpectrogram

@Suite("Split Complex")
struct TestSplitComplex {

    @Test func testSplitComplexAddition() async throws {
        let cpx1 = self.makeRandomComplex()
        let cpx2 = self.makeRandomComplex()
        
        let addition = cpx1 + cpx2
        #expect(addition.real == cpx1.real + cpx2.real)
        #expect(addition.imag == cpx1.imag + cpx2.imag)
    }
    
    @Test func testSplitComplexSubtraction() async throws {
        let cpx1 = self.makeRandomComplex()
        let cpx2 = self.makeRandomComplex()

        
        let subtraction = cpx1 - cpx2
        #expect(subtraction.real == cpx1.real - cpx2.real)
        #expect(subtraction.imag == cpx1.imag - cpx2.imag)
    }
    
    
    @Test func testComplexMultiplication() async throws {
        let cpx1 = self.makeRandomComplex()
        let cpx2 = self.makeRandomComplex()

        let multiplication = cpx1 * cpx2
        #expect(multiplication.real == cpx1.real * cpx2.real - cpx1.imag * cpx2.imag)
        #expect(multiplication.imag == cpx1.real * cpx2.imag + cpx1.imag * cpx2.real)
    }
    
    
    @Test func testComplexMultiplicationInPlace() async throws {
        var cpx1 = self.makeRandomComplex()
        let cpx2 = self.makeRandomComplex()
        
        let cpx1Copy = DSPComplex(real: cpx1.real, imag: cpx1.imag)
        cpx1 *= cpx2
        
        #expect(cpx1.real == cpx1Copy.real * cpx2.real - cpx1Copy.imag * cpx2.imag)
        #expect(cpx1.imag == cpx1Copy.real * cpx2.imag + cpx1Copy.imag * cpx2.real)
    }
    
    
    
    @Test func testMultiplicationComplexConjugate() async throws {
        let cpx1 = self.makeRandomComplex()
        
        let squaredNorm = cpx1 * cpx1.conjugate()
        #expect(squaredNorm.imag == 0)
        #expect(abs(squaredNorm.real - cpx1.magnitude * cpx1.magnitude) < 10e-7)
    }
    
    
    
    
    private func makeRandomComplex() -> DSPComplex {
        var randomRange: Range<Float>

        repeat {
            let someRandom: Float = Float.random(in: 0..<1)
            let someOtherRandom: Float = Float.random(in: 0..<1)
            randomRange = min(someRandom, someRandom)..<max(someRandom, someOtherRandom)
        } while(randomRange.isEmpty)
        
        let a = Float.random(in: randomRange)
        let b = Float.random(in: randomRange)

        return DSPComplex(real: a, imag: b)
    }
}
