import Accelerate

/// An object of this class stores a matrix whose rows are eigenvectors of another matrix.
/// Eigenvalues match positions with respect to the major: For example in case of column major `eigenValue[0]` refers to row `0` of the matrix of eigenvectors, and more generally
/// for every valid `i`, `eigenValue[i]` refers to minor `i` of the matrix of eigenvectors.
public final class EigenvectorDecompositionComplex {
    private let matrixOfEigeinvectors: DenseComplexMatrix
    private let eigenvalues: SplitDoubleComplexArray
    private let layout: MatrixLayout
    
    internal init(
        matrixOfEigeinvectors: DenseComplexMatrix,
        eigenvalues: SplitDoubleComplexArray,
        layout: MatrixLayout
    ) {
        self.matrixOfEigeinvectors = matrixOfEigeinvectors
        self.eigenvalues = eigenvalues
        self.layout = layout
    }
    
    public final func getEigenvectors() -> DenseComplexMatrix {
        return self.matrixOfEigeinvectors
    }
    
    public final func getEigenvalues() -> SplitDoubleComplexArray {
        return self.eigenvalues
    }
    
    public final func getLayout() -> MatrixLayout {
        return self.layout
    }
}
