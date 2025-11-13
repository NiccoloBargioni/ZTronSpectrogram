import Accelerate

public final class HouseholderDecomposition {
    private let diagonal: [Double]
    private let offDiagonal: [Double]
    private let householderScalars: [Double]
    private let orthogonalMatrix: DenseRealMatrix
    private let size: Int
    
    /// Given any matrix A with real coefficients, an object of this class represents its bidiagonal representation obtained via Householder Decomposition.
    /// Such decompostion factors A into the following product:
    ///
    /// `A = Q·T·Q^t`
    ///
    /// Where
    /// - `Q` is an orthogonal matrix, that is, a matrix that satisfies `Q·Q^t = Q^t·Q = Id`
    /// - `A` is any `n×n` matrix with real coefficients.
    /// - `Q` is a square matrix of size `n×n`
    /// - `T` is a tridiagonal, symmetrical matrix of size `n×n`
    ///
    /// `T` has the following structure:
    ///
    ///     [ d1    e1    0   0   ...   0    ]
    ///     [ e1    d2    e2  0   ....  0    ]
    ///     [  0    e2    d3  ⋱   ...  0    ]
    ///     [  ⋮      ⋱     ⋱     ...  0    ]
    ///     [  0 ... e_{n-2} d_{n-1} e_{n-1} ]
    ///     [  0 ... 0       e_{n-1} d_n     ]
    internal init(
        orthogonalMatrix: [Double],
        diagonal: [Double],
        offDiagonal: [Double],
        householderScalars: [Double],
        rowsOfDecomposedMatrix: Int,
    ) {
        self.diagonal = diagonal
        self.offDiagonal = offDiagonal
        self.householderScalars = householderScalars
        self.size = rowsOfDecomposedMatrix
        
        self.orthogonalMatrix = DenseRealMatrix(
            wrapping: orthogonalMatrix,
            rows: rowsOfDecomposedMatrix,
            columns: rowsOfDecomposedMatrix
        )

    }
    
    /// Returns an orthogonal matrix `Q`, that is, `Q·Q^t = Q^t·Q = Id`, that participates in the Householder decomposition of some square matrix A.
    public func getOrthogonalMatrix() -> DenseRealMatrix {
        return self.orthogonalMatrix
    }
    
    /// Returns the diagonal elements of the `T` matrix in the Householder decomposition of some square matrix `A`, that is, it represents `d_i, i in 0..<A.rows`
    public func getDiagonal() -> [Double] {
        return self.diagonal
    }
    
    /// Returns the subdiagonal and superdiagonal elements of the matrix `T`, that is, it represents `e_i, i in 0..<A.rows`
    public func getOffDiagonal() -> [Double] {
        return self.offDiagonal
    }
    
    public func getHouseholderScalars() -> [Double] {
        return self.householderScalars
    }
    
    /// This method computes the tridiagonal matrix originating from the householder decomposition of the matrix `A = Q·T·Q^t`
    public final func buildTridiagonalMatrix() -> DenseRealMatrix {
        var TMatrix: [Double] = .init(repeating: .zero, count: 9)
        
        for i in 0..<3 {
            TMatrix[i * 3 + i] = self.diagonal[i]
        }
        
        for i in 0..<3 {
            if i - 1 >= 0 {
                TMatrix[i * 3 + (i - 1)] = self.offDiagonal[i - 1]
            }
            
            if i < 2 {
                TMatrix[i * 3 + (i + 1)] = self.offDiagonal[i]
            }
        }

        return DenseRealMatrix(wrapping: TMatrix, rows: 3, columns: 3)
    }
    
    /// This method computes a matrix entirely composed of eigenvectors for T such that `A = Q·T·Q^t`, where `T` is a tridiagonal matrix, as well as it computes the matching eigenvalues.
    public final func getEigenvectorDecompositon() throws -> EigenvectorDecomposition<Double> {
        var eigenvectorMatrix = Array<Double>.init(repeating: 0.0, count: self.size * self.size)
        
        for i in 0..<diagonal.count {
            eigenvectorMatrix[i * diagonal.count + i] = 1.0
        }
        
        var lapackExitCode: Int32 = 0
        var computeMode: Int8 = 86 // V
    
        var rowsAndColsCount: Int32 = Int32(self.diagonal.count)
        var majorDimensions: Int32 = Int32(self.diagonal.count)
        
        var diagonalElements = self.diagonal.vDSP_copy()
        var subdiagonalElements = self.offDiagonal.vDSP_copy()
        var work = [Double](repeating: 0.0, count: max(1, 2 * Int(self.size) - 2))
        
        dsteqr_(
            &computeMode,
            &rowsAndColsCount,
            &diagonalElements,
            &subdiagonalElements,
            &eigenvectorMatrix,
            &majorDimensions,
            &work,
            &lapackExitCode
        )
        
        if lapackExitCode != 0 {
            throw MatrixError.lapackError("Lapack method dsteqr_ failed with exit code \(lapackExitCode).")
        }
        
        return EigenvectorDecomposition(
            matrixOfEigeinvectors: eigenvectorMatrix,
            eigenvalues: diagonalElements,
            rowsAndColumnsCount: self.size,
            layout: .columnMajor
        )
    }
}
