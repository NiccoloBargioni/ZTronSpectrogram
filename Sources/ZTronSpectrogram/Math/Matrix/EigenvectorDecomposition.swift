import Foundation

/// An object of this class stores a matrix whose rows are eigenvectors of another matrix.
/// Eigenvalues match positions with respect to the row: For example `eigenValue[0]` refers to row `0` of the matrix of eigenvectors, and more generally
/// for every valid `i`, `eigenValue[i]` refers to row `0` of the matrix of eigenvectors.
public final class EigenvectorDecomposition {
    private let matrixOfEigeinvectors: DenseRealMatrix
    private let eigenvalues: [Double]
    
    public init(
        matrixOfEigeinvectors: [Double],
        eigenvalues: [Double],
        rowsAndColumnsCount: Int
    ) {
        self.matrixOfEigeinvectors = DenseRealMatrix(
            wrapping: matrixOfEigeinvectors,
            rows: rowsAndColumnsCount,
            columns: rowsAndColumnsCount
        )
        
        self.eigenvalues = eigenvalues
    }
    
    public final func getEigenvectors() -> DenseRealMatrix {
        return self.matrixOfEigeinvectors
    }
    
    public final func getEigenvalues() -> [Double] {
        return self.eigenvalues
    }
}
