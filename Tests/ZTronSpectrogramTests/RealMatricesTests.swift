import Testing
import Accelerate

@testable import ZTronSpectrogram

@Suite("Matrices")
struct TestRealMatrices {
    
    @Test func arrayClone() async throws {
        var someRandomArray: [Double] = .init()
        
        for _ in 0..<10_000 {
            someRandomArray.append(Double.random(in: 0..<1))
        }
        
        var clone = someRandomArray.vDSP_copy()
        
        someRandomArray.withUnsafeMutableBufferPointer { sraPtr in
            clone.withUnsafeMutableBufferPointer { clonePtr in
                #expect(sraPtr.baseAddress != clonePtr.baseAddress)
            }
        }
        for i in 0..<10_000 {
            #expect(someRandomArray[i] == clone[i])
        }
        
    }
    
    @Test func testExtractColumn() async throws {
        let matrix: DenseRealMatrix = .init(
            wrapping: [4.0, 2.0, 1.0, 2.0, 5.0, 3.0, 1.0, 3.0, 6.0],
            rows: 3,
            columns: 3
        )
        
        let secondCol = matrix.column(1)
        print(secondCol.description)
    }
    
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
                    #expect(firstMatrix[i][j] == mm[i][j])
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
    
    
    @Test func testEigenvaluesAndVectors() async throws {
        let matrix = DenseRealMatrix(wrapping: [4.0, 2.0, 1.0, 2.0, 5.0, 3.0, 1.0, 3.0, 6.0], rows: 3, columns: 3)
        
        do {
            let householder = try matrix.tridiagonalDecomposition()
            let T = householder.buildTridiagonalMatrix()
            let eigenvectorDecomposition = try householder.getEigenvectorDecompositon()
            let eigenvectors = eigenvectorDecomposition.getEigenvectors()
            
            
            for i in 0..<3 {
                let eigenVector = eigenvectors[i]
                let expectedOutput = try T * DenseRealMatrix(wrapping: eigenVector, rows: 1, columns: 3).transposed()
                                
                var estimatedLambda: [Double] = []
                for j in 0..<3 {
                    estimatedLambda.append(expectedOutput[j][0] / eigenVector[j])
                }
                
                for j in 0..<2 {
                    #expect(abs(estimatedLambda[j] - estimatedLambda[j + 1]) < 10e-15)
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
    
    @Test func testHessenbergDecomposition() async throws {
        let size = 10
        var someRandomMatrix = Array<Double>.init()
        someRandomMatrix.reserveCapacity(size * size)
        
        for _ in 0..<size {
            for _ in 0..<size {
                someRandomMatrix.append(Double.random(in: 0..<1))
            }
        }
        let matrix = DenseRealMatrix(wrapping: someRandomMatrix, rows: size, columns: size)


        do {
            let hessenberg = try matrix.hessenbergReduction()
            let hessenbergMatrix = hessenberg.getHessenbergMatrix()
            
            for i in 0..<size {
                for j in 0..<size {
                    if j >= i - 1 {
                        break
                    } else {
                        #expect(abs(hessenbergMatrix[i][j]) < 10e-15)
                    }
                }
            }
            
            let reducer = hessenberg.getReducerMatrix()
            
            let A = try reducer * hessenbergMatrix * reducer.transposed()
                        
            for i in 0..<size {
                for j in 0..<size {
                    #expect(abs(A[i][j] - matrix[i][j]) < 10e-14)
                }
            }
            
            let I = try reducer * reducer.transposed()
            
            for i in 0..<size {
                for j in 0..<size {
                    if i != j {
                        #expect(abs(I[i][j]) < 10e-15)
                    } else {
                        #expect(abs(I[i][j] - 1.0) < 10e-15)
                    }
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
