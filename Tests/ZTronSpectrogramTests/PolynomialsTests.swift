import Testing
import Accelerate

@testable import ZTronSpectrogram

@Suite("Polynomials")
struct TestPolynomial {
    @Test func testPolynomialEval() async throws {
        let poly = Polynomial<DSPComplex>(coefficients: 1,2,3,4,5)
        
        let x: Float = Float.random(in: 0..<1)
        let expectedOutput: Float = pow(x, 4) + 2*pow(x, 3) + 3*pow(x, 2) + 4*x + 5
        
        let eval = poly.at(x: DSPComplex(real: x, imag: .zero))
        
        #expect(abs(expectedOutput - eval.real) < 10e-6)
    }
    
    
    @Test func testPolynomialInitWithLeadingZeroCoefficient() async throws {
        let poly = Polynomial<DSPComplex>(coefficients: 0,0,3,4,5)
        
        let x: Float = Float.random(in: 0..<1)
        let expectedOutput: Float = 3*pow(x, 2) + 4*x + 5
        
        let eval = poly.at(x: DSPComplex(real: x, imag: .zero))
        
        #expect(abs(expectedOutput - eval.real) < 10e-6)
    }
    
}
