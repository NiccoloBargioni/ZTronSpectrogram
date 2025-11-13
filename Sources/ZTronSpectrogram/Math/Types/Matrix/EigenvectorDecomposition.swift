import Foundation

/// An object of this class stores a matrix whose rows are eigenvectors of another matrix.
/// Eigenvalues match positions with respect to the row: For example `eigenValue[0]` refers to row `0` of the matrix of eigenvectors, and more generally
/// for every valid `i`, `eigenValue[i]` refers to row `0` of the matrix of eigenvectors.
public final class EigenvectorDecomposition<Eigenvalue: Numeric & AlgebraicField & VectorSpace> {
    private let matrixOfEigeinvectors: DenseRealMatrix
    private let eigenvalues: [Eigenvalue]
    private let layout: MatrixLayout
    
    internal init(
        matrixOfEigeinvectors: [Double],
        eigenvalues: [Eigenvalue],
        rowsAndColumnsCount: Int,
        layout: MatrixLayout
    ) {
        self.matrixOfEigeinvectors = DenseRealMatrix(
            wrapping: matrixOfEigeinvectors,
            rows: rowsAndColumnsCount,
            columns: rowsAndColumnsCount
        )
        
        self.eigenvalues = eigenvalues
        self.layout = layout
    }
    
    public final func getEigenvectors() -> DenseRealMatrix {
        return self.matrixOfEigeinvectors
    }
    
    public final func getEigenvalues() -> [Eigenvalue] {
        return self.eigenvalues
    }
    
    public final func getLayout() -> MatrixLayout {
        return self.layout
    }
}
