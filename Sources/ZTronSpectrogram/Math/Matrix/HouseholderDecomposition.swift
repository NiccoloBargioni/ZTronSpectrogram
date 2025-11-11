import Foundation

public final class HouseholderDecomposition {
    private let diagonal: [Double]
    private let offDiagonal: [Double]
    private let householderScalars: [Double]
    private let orthogonalMatrix: DenseRealMatrix
    
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
}
