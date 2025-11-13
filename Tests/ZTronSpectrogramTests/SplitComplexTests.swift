import Testing
import Foundation
import Accelerate

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
    
    
    @Test func testProductByScalarRHS() async throws {
        let cpx1 = self.makeRandomComplex()
        let randomScalar = Float.random(in: 0..<1)
        
        let scaled = cpx1 * randomScalar
        
        #expect(scaled.real == cpx1.real * randomScalar)
        #expect(scaled.imag == cpx1.imag * randomScalar)
    }
    
    @Test func testProductByScalarLHS() async throws {
        let cpx1 = self.makeRandomComplex()
        let randomScalar = Float.random(in: 0..<1)
        
        let scaled = randomScalar * cpx1
        
        #expect(scaled.real == cpx1.real * randomScalar)
        #expect(scaled.imag == cpx1.imag * randomScalar)
    }
    
    @Test func testProductByScalarInPlace() async throws {
        var cpx1 = self.makeRandomComplex()
        let randomScalar = Float.random(in: 0..<1)
        
        let cpx1Copy = DSPComplex(real: cpx1.real, imag: cpx1.imag)
        cpx1 *= randomScalar
        
        #expect(cpx1.real == cpx1Copy.real * randomScalar)
        #expect(cpx1.imag == cpx1Copy.imag * randomScalar)
    }
    
    @Test func testComplexDivision() async throws {
        let cpx1 = self.makeRandomComplex()
        let cpx2 = self.makeRandomComplex()
        
        let cpx2Norm2 = cpx2.magnitude * cpx2.magnitude
        
        let div = cpx1 / cpx2
        #expect(abs(div.real - (cpx1.real * cpx2.real + cpx1.imag * cpx2.imag) / cpx2Norm2) < 10e-6)
        #expect(abs(div.imag - (-1*cpx1.real * cpx2.imag + cpx1.imag * cpx2.real) / cpx2Norm2) < 10e-6)
    }
    
    
    @Test func testComplexDivisionByLHSScalar() async throws {
        let cpx2 = self.makeRandomComplex()
        
        let cpx2Norm2 = cpx2.magnitude * cpx2.magnitude
        let randomFloat = Float.random(in: 0..<1)
        
        let div = randomFloat / cpx2
        #expect(abs(div.real - randomFloat * cpx2.real / cpx2Norm2) < 10e-6)
        #expect(abs(div.imag + (randomFloat * cpx2.imag) / cpx2Norm2) < 10e-6)
    }
    
    
    @Test func testComplexDivisionByRHSScalar() async throws {
        let cpx2 = self.makeRandomComplex()
        
        let randomFloat = Float.random(in: 0..<1)
        
        let div = cpx2 / randomFloat
        
        #expect(abs(div.real - cpx2.real / randomFloat) < 10e-6)
        #expect(abs(div.imag - cpx2.imag / randomFloat) < 10e-6)
    }
    
    
    @Test func testComplexDivisionInPlace() async throws {
        var cpx1 = self.makeRandomComplex()
        let cpx2 = self.makeRandomComplex()
        
        let cpx2Norm2 = cpx2.magnitude * cpx2.magnitude
        let cpx1Copy = DSPComplex(real: cpx1.real, imag: cpx1.imag)
        
        cpx1 /= cpx2
        
        #expect(abs(cpx1.real - (cpx1Copy.real * cpx2.real + cpx1Copy.imag * cpx2.imag) / cpx2Norm2) < 10e-6)
        #expect(abs(cpx1.imag - (-1*cpx1Copy.real * cpx2.imag + cpx1Copy.imag * cpx2.real) / cpx2Norm2) < 10e-6)
    }
    
    @Test func testDSPComplexZero() async throws {
        let complexZero: DSPComplex = DSPComplex(0)
        #expect(complexZero.real == .zero)
        #expect(complexZero.imag == .zero)
        
        let cpx0: DSPComplex = .zero
        #expect(cpx0.real == .zero)
        #expect(cpx0.imag == .zero)
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
    
    
    @Test func testSplitComplexArraySample() async throws {
        let reals = UnsafeMutablePointer<Double>.allocate(capacity: 4 * 4)
        let imags = UnsafeMutablePointer<Double>.allocate(capacity: 4 * 4)
        
        [
            -0.488, 0.086, 0.086, -0.131,
            0.327, -0.158, -0.158, -0.302,
            -0.758, 0.502, 0.502, 0.429,
            0.284, -0.096, -0.096, 1.460
        ].enumerated().forEach { i, realPart in
            reals[i] = realPart
        }
        
        [
            0.0, 0.239, 0.239, 0.0,
            0.0, 0.243, 0.243, 0.0,
            0.0, 0.454, 0.454, 0.0,
            0.0, 0.413, 0.413, 0.000
        ].enumerated().forEach { i, imagPart in
            imags[i] = imagPart
        }
        
        let complex = SplitDoubleComplexArray(
            array: DSPDoubleSplitComplex(realp: reals, imagp: imags),
            size: 16
        )

        let initialOffset: Int = 1
        let samples = complex.takeSamples(stride: 4, initialOffset: initialOffset)
        
        for i in 0..<4 {
            #expect(abs(samples[i].real - reals[4 * i + initialOffset]) < 10e-15)
            #expect(abs(samples[i].imag - imags[4 * i + initialOffset]) < 10e-15)
        }
    }
}
