import Testing
import Accelerate

@testable import ZTronSpectrogram

@Suite("Matrices")
struct TestRealMatrices {
    
    @Test func testMatrixTransposition() async throws {
        let matrix: DenseRealMatrix = .init(
            wrapping: [4.0, 2.0, 1.0, 2.0, 5.0, 3.0],
            rows: 2,
            columns: 3
        )
        
        
        let transposed = matrix.transposed()
        
        for i in 0..<2 {
            for j in 0..<3 {
                #expect(matrix[i][j] == transposed[j][i])
            }
        }
    }
    
    @Test func testMatrixMultiplication() async throws {
        let firstMatrix: DenseRealMatrix = .init(
            wrapping: [4.0, 2.0, 1.0, 2.0, 5.0, 3.0, 1.0, 3.0, 6.0],
            rows: 3,
            columns: 3
        )
        
        let secondMatrix: DenseRealMatrix = .init(
            wrapping: [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0],
            rows: 3,
            columns: 3
        )
        
        do {
            let mm = try firstMatrix * secondMatrix
            for i in 0..<3 {
                for j in 0..<3 {
                    print(mm[i][j])
                }
            }
        } catch let error as MatrixError {
            if case MatrixError.invalidDimension(let errorMessage) = error {
                print(errorMessage)
            }
        } catch {
            fatalError(error.localizedDescription)
        }

    }
    
    @Test func testTridiagonalDecomposition() async throws {
        let matrix = DenseRealMatrix(wrapping: [4.0, 2.0, 1.0, 2.0, 5.0, 3.0, 1.0, 3.0, 6.0], rows: 3, columns: 3)
        
        do {
            let householder = try matrix.tridiagonalDecomposition()
            let Q = householder.getOrthogonalMatrix()
            let identity = try Q * Q.transposed()
            
            for i in 0..<3 {
                for j in 0..<3 {
                    if i == j {
                        #expect(abs(identity[i][j] - 1.0) < 10e-15)
                    } else {
                        #expect(abs(identity[i][j]) < 10e-15)
                    }
                }
            }
            
            var TMatrix: [Double] = .init(repeating: .zero, count: 9)
            let diagonalT: [Double] = householder.getDiagonal()
            let offDiagIT: [Double] = householder.getOffDiagonal()
            for i in 0..<3 {
                TMatrix[i * 3 + i] = diagonalT[i]
            }
            
            for i in 0..<3 {
                if i - 1 >= 0 {
                    TMatrix[i * 3 + (i - 1)] = offDiagIT[i - 1]
                }
                
                if i < 2 {
                    TMatrix[i * 3 + (i + 1)] = offDiagIT[i]
                }
            }

            let T = DenseRealMatrix(wrapping: TMatrix, rows: 3, columns: 3)
            
            let reconstructedA = try Q * T * Q.transposed()
            
            for i in 0..<3 {
                for j in 0..<3 {
                    #expect(abs(reconstructedA[i][j] - matrix[i][j]) < 10e-15)
                }
            }
        } catch let error as MatrixError {
            if case MatrixError.invalidDimension(let errorMessage) = error {
                print(errorMessage)
            }
        } catch {
            fatalError(error.localizedDescription)
        }
        
    }
}
