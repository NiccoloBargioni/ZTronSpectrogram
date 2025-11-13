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
            var hessenbergMatrix = hessenberg.getHessenbergMatrix()
            
            if hessenberg.getMatrixLayout() == .columnMajor {
                hessenbergMatrix = hessenbergMatrix.transposed()
            }
            
            for i in 0..<size {
                for j in 0..<size {
                    if j >= i - 1 {
                        break
                    } else {
                        #expect(abs(hessenbergMatrix[i][j]) < 10e-15)
                    }
                }
            }
            
            var reducer = hessenberg.getReducerMatrix()
            if hessenberg.getMatrixLayout() == .columnMajor {
                reducer = reducer.transposed()
            }
            
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
    
    
    @Test func testSchurCanonicalForm() async throws {
        var schurrMatrix: [Double] = [
            0.33020202156972756, 0.0, 0.0, 0.0, // Column 0
            1.103748522132219, 1.6879989982001642, 2.1882779713574565, 0.0, // Column 1
            -2.2931678652962897, -0.37857003411018075,  1.6879989982001642, 0.0, // Column 2
            -1.343283403310561, -1.4561142135178406, -0.0986547204745938, 3.293799982029939 // Column 3
        ]
        
        var schurrVectors: [Double] = [
            -0.4883550630451622, 0.32709923398383733, -0.7576197204218585, 0.2837741756278156,
             0.7718104490878924, -0.029064543327584423, -0.5941654449290507, -0.22456915872881456,
             -0.009618604338247374, 0.821078239243315, 0.15495227225599398, -0.5492975521649305,
             0.4070939025918781, 0.4668959932248741, 0.22129070609239634, 0.7532019047906087
        ]
        
        let sm = DenseRealMatrix(wrapping: schurrMatrix, rows: 4, columns: 4)
        let sv = DenseRealMatrix(wrapping: schurrVectors, rows: 4, columns: 4)
        
        do {
            let A = try sv.transposed() * sm.transposed() * sv
            let recomposedMatrix = DenseRealMatrix(
                wrapping: [1.0, 1.0, 0.0, 0.0, 2.0, 1.0, -1.0, 0.0, 0.0, 3.0, 2.0, 1.0, 0.0, 0.0, 1.0, 3.0],
                rows: 4,
                columns: 4
            )
            
            for i in 0..<4 {
                for j in 0..<4 {
                    #expect(abs(A[i][j] - recomposedMatrix[i][j]) < 10e-10)
                }
            }
            
            let eigenValuesReals = UnsafeMutablePointer<Double>.allocate(capacity: 4)
            let eigenValuesImagp = UnsafeMutablePointer<Double>.allocate(capacity: 4)

            
            [0.330202, 1.688, 1.688, 3.2938].enumerated().forEach { i, eigReal in
                eigenValuesReals[i] = eigReal
            }
            
            [0.0, 0.9101742468340883, -0.9101742468340883, 0.0].enumerated().forEach { i, eigImag in
                eigenValuesImagp[i] = eigImag
            }
            
            let eigenvalues: DSPDoubleSplitComplex = .init(
                realp: eigenValuesReals,
                imagp: eigenValuesImagp
            )
            
            let eigenvectors = try HessenbergDecomposition.computeEigenvectorsFromSchur(
                schurCanonicalForm: &schurrMatrix,
                schurVectors: &schurrVectors,
                eigenvalues: SplitDoubleComplexArray(array: eigenvalues, size: 4)
            )
                        
            for i in 0..<4 {
                let ithEigenvector = eigenvectors.column(i)
                
                let ithEigenvalue = SplitDoubleComplexArray(array: eigenvalues, size: 4)[i]
                var ithReconstructedEigenvector: [DSPDoubleComplex] = .init(repeating: .zero, count: 4)
                
                for row in 0..<4 {
                    var sum = DSPDoubleComplex.zero
                    for col in 0..<4 {
                        let a = DSPDoubleComplex(real: A[row][col], imag: 0)
                        let b = ithEigenvector[col][0]
                        sum = sum + (a * b)
                    }
                    ithReconstructedEigenvector[row] = sum
                }
                                
                var lambdaTimesV: [DSPDoubleComplex] = .init(repeating: .zero, count: 4)
                for row in 0..<4 {
                    lambdaTimesV[row] = ithEigenvalue * ithEigenvector[row][0]
                }
                
                for row in 0..<4 {
                    let difference = ithReconstructedEigenvector[row] - lambdaTimesV[row]
                    #expect(abs(difference.real) < 10e-7)
                    #expect(abs(difference.imag) < 10e-7)
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
    
    
    @Test func eigenOfNonSymmetricMatrix() async throws {
        do {
            let A = DenseRealMatrix(
                wrapping: [1.0, 1.0, 0.0, 0.0, 2.0, 1.0, -1.0, 0.0, 0.0, 3.0, 2.0, 1.0, 0.0, 0.0, 1.0, 3.0],
                rows: 4,
                columns: 4
            )
            
            let hessenberg = try A.hessenbergReduction()
            let eigens = try hessenberg.getEigenvectorDecomposition()
            
            for i in 0..<4 {
                let ithEigenvector = eigens.getEigenvectors().column(i)
                
                let ithEigenvalue = eigens.getEigenvalues()[i]
                var ithReconstructedEigenvector: [DSPDoubleComplex] = .init(repeating: .zero, count: 4)
                
                for row in 0..<4 {
                    var sum = DSPDoubleComplex.zero
                    for col in 0..<4 {
                        let a = DSPDoubleComplex(real: A[row][col], imag: 0)
                        let b = ithEigenvector[col][0]
                        sum = sum + (a * b)
                    }
                    ithReconstructedEigenvector[row] = sum
                }
                                
                var lambdaTimesV: [DSPDoubleComplex] = .init(repeating: .zero, count: 4)
                for row in 0..<4 {
                    lambdaTimesV[row] = ithEigenvalue * ithEigenvector[row][0]
                }
                
                for row in 0..<4 {
                    let difference = ithReconstructedEigenvector[row] - lambdaTimesV[row]
                    #expect(abs(difference.real) < 10e-15)
                    #expect(abs(difference.imag) < 10e-15)
                }
            }        } catch let error as MatrixError {
            if case MatrixError.invalidDimension(let errorMessage) = error {
                print(errorMessage)
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
