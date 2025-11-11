import QuartzCore
import Testing
import Accelerate
@testable import ZTronSpectrogram

@Suite("Functions")
struct TestFunctions {
    @Test func testEvaluateRealToReal() async throws {
        let sine = Function<Float, Float> { t in
            return sin(t)
        }
        
        let randomTest = Float.random(in: 0..<1)
        
        #expect(sine.at(x: randomTest) == sin(randomTest))
    }
    
    
    @Test func testEvaluateComplexToReal() async throws {
        let norm2 = Function<DSPComplex, Float> { z in
            return sqrt(z.real * z.real + z.imag * z.imag)
        }
        
        let someRandomComplex = DSPComplex(real: Float.random(in: 0..<1), imag: Float.random(in: 0..<1))
        
        #expect(abs(norm2.at(x: someRandomComplex) - someRandomComplex.magnitude) < 10e-7)
    }
    
    
    @Test func testEvaluateComplexToComplex() async throws {
        let exp = Function<DSPComplex, DSPComplex> { z in
            let coefficient: Float = QuartzCore.exp(z.real)
            
            return DSPComplex(real: coefficient * cos(z.imag), imag: coefficient * sin(z.imag))
        }
        
        let someRandomPhase: Float = Float.random(in: 0..<2*Float.pi)
        let someRandomComplex = DSPComplex(real: cos(someRandomPhase), imag: sin(someRandomPhase))
        
        #expect(abs(exp.at(x: someRandomComplex).magnitude - QuartzCore.exp(someRandomComplex.real)) < 10e-7)
    }
    
    
    @Test func testFunctionSampleWithStride() async throws {
        let sinx = Function<Float, Float> { t in
            return sin(t)
        }
        
        let sampledFunction = sinx.sample(range: 0...2*Float.pi, stride: 0.01)
        
        #expect(sampledFunction[0] == sinx.at(x: 0))
        
        let expectedSamplesCount = Int(floor((2*Float.pi) / 0.01)) + 1
        
        #expect(sampledFunction.count == expectedSamplesCount)
    }
    
    
    
    @Test func testFunctionSampleWithMultipleOfStride() async throws {
        let sinx = Function<Float, Float> { t in
            return sin(t)
        }
        
        let sampledFunction = sinx.sample(range: 0...10, stride: 0.01)
        
        #expect(sampledFunction[0] == sinx.at(x: 0))
        #expect(sampledFunction.last! == sinx.at(x: 10.0))
        
        let expectedSamplesCount = Int(floor(10.0 / 0.01)) + 1
        
        #expect(sampledFunction.count == expectedSamplesCount)
    }
    
    
    @Test func testFunctionSampleWithSamplesCount() async throws {
        let sinx = Function<Float, Float> { t in
            return sin(t)
        }
        
        let sampledFunction = sinx.sample(range: 0...2*Float.pi, taking: 15)
        
        #expect(sampledFunction[0] == sinx.at(x: 0))
        #expect(sampledFunction.last! == sinx.at(x: 2*Float.pi))
        #expect(sampledFunction.count == 15)
    }
    
}
