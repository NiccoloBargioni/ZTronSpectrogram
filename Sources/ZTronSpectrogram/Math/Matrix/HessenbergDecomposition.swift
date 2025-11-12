import Foundation

public final class HessenbergDecomposition {
    private let hessenbergMatrix: DenseRealMatrix
    private let reducerMatrix: DenseRealMatrix
    
    public init(
        hessenbergMatrix: [Double],
        reducerMatrix: [Double],
        size: Int
    ) {
        self.hessenbergMatrix = DenseRealMatrix(wrapping: hessenbergMatrix, rows: size, columns: size).transposed()
        self.reducerMatrix = DenseRealMatrix(wrapping: reducerMatrix, rows: size, columns: size).transposed()
    }
    
    public final func getHessenbergMatrix() -> DenseRealMatrix {
        return self.hessenbergMatrix
    }
    
    public final func getReducerMatrix() -> DenseRealMatrix {
        return self.reducerMatrix
    }
    
}
