import Accelerate

public final class DenseRealMatrix: CustomStringConvertible {
    public var description: String {
        return self.toString()
    }
    
    private var matrix: [Double]
    private let rows: Int
    private let columns: Int
    
    public init(wrapping: [Double], rows: Int, columns: Int) {
        self.matrix = wrapping
        self.rows = rows
        self.columns = columns
    }
    
    
    func tridiagonalDecomposition() throws -> HouseholderDecomposition {
        guard self.rows == self.columns else {
            throw MatrixError.invalidDimension("Tridiagonal Householder Decomposition is only defined for square matrices.")
        }

        var matrix = self.matrix
        var matrixDimension = Int32(self.rows)
        var triangleSpecifier: Int8 = 76
        var leadingDimension = matrixDimension
        
        var diagonalElements = [Double](repeating: 0.0, count: Int(matrixDimension))
        var offDiagonalElements = [Double](repeating: 0.0, count: Int(matrixDimension - 1))
        var householderScalars = [Double](repeating: 0.0, count: Int(matrixDimension - 1))
        
        var workspaceQuery: Double = 0.0
        var workspaceSize: Int32 = -1
        var statusInfo: Int32 = 0
        
        dsytrd_(&triangleSpecifier, &matrixDimension, &matrix, &leadingDimension,
                &diagonalElements, &offDiagonalElements, &householderScalars,
                &workspaceQuery, &workspaceSize, &statusInfo)
        
        workspaceSize = Int32(workspaceQuery)
        var workspace = [Double](repeating: 0.0, count: Int(workspaceSize))
        
        dsytrd_(&triangleSpecifier, &matrixDimension, &matrix, &leadingDimension,
                &diagonalElements, &offDiagonalElements, &householderScalars,
                &workspace, &workspaceSize, &statusInfo)
        
        guard statusInfo == 0 else {
            fatalError("dsytrd failed with info = \(statusInfo)")
        }
        
        workspaceSize = -1
        dorgtr_(&triangleSpecifier, &matrixDimension, &matrix, &leadingDimension,
                &householderScalars, &workspaceQuery, &workspaceSize, &statusInfo)
        
        workspaceSize = Int32(workspaceQuery)
        workspace = [Double](repeating: 0.0, count: Int(workspaceSize))
        
        dorgtr_(&triangleSpecifier, &matrixDimension, &matrix, &leadingDimension,
                &householderScalars, &workspace, &workspaceSize, &statusInfo)
        
        guard statusInfo == 0 else {
            fatalError("dorgtr failed with info = \(statusInfo)")
        }
        
        return HouseholderDecomposition(
            orthogonalMatrix: matrix,
            diagonal: diagonalElements,
            offDiagonal: offDiagonalElements,
            householderScalars: householderScalars,
            rowsOfDecomposedMatrix: self.rows
        )
    }
    
    
    public final func transposed() -> DenseRealMatrix {
        let result = UnsafeMutableBufferPointer<Double>.allocate(capacity: self.rows * self.columns)
        defer {
            result.deallocate()
        }

        vDSP_mtransD(
            self.matrix,
            1,
            result.baseAddress!,
            1,
            vDSP_Length(self.columns),
            vDSP_Length(self.rows)
        )
        
        return DenseRealMatrix(wrapping: Array(result), rows: self.columns, columns: self.rows)
    }
    
    public static func * (lhs: DenseRealMatrix, rhs: DenseRealMatrix) throws -> DenseRealMatrix {
        guard lhs.columns == rhs.rows else {
            throw MatrixError.invalidDimension("In matrix multiplication ")
        }

        let result = UnsafeMutableBufferPointer<Double>.allocate(capacity: lhs.rows * rhs.columns)
        defer {
            result.deallocate()
        }
        
        lhs.matrix.withUnsafeBufferPointer { aPtr in
            rhs.matrix.withUnsafeBufferPointer { bPtr in
                cblas_dgemm(
                    CblasRowMajor,
                    CblasNoTrans,
                    CblasNoTrans,
                    Int32(lhs.rows), // rows of A and C
                    Int32(rhs.columns), // columns of B and C
                    Int32(lhs.columns), // columns of A, rows of B
                    1.0, // alpha
                    aPtr.baseAddress, // A
                    Int32(lhs.columns), // lda: columns of A (row-major)
                    bPtr.baseAddress, // B
                    Int32(rhs.columns), // ldb: columns of B (row-major)
                    0.0, // beta
                    result.baseAddress, // C
                    Int32(rhs.columns) // ldc: columns of C (row-major)
                )
            }
        }
        
        return DenseRealMatrix(wrapping: Array(result), rows: lhs.rows, columns: rhs.columns)
    }
    
    subscript(index: Int) -> [Double] {
        return Array(self.matrix[ index*self.columns...(index + 1)*self.columns - 1])
    }
    
    private final func toString() -> String {
        var stringRepresentation = "[\n"
        
        for i in 0..<self.rows {
            var rowStringRepresentation = "  ["
            for j in 0..<self.columns {
                rowStringRepresentation += "\(String(format: "%.3f", self.matrix[i * self.columns + j]))"
                if j < self.columns - 1 {
                    rowStringRepresentation += ",  "
                }
            }
            rowStringRepresentation += "]"
            
            if i < self.rows - 1 {
                rowStringRepresentation += ","
            }
            
            rowStringRepresentation += "\n"
            stringRepresentation+=rowStringRepresentation
        }
        
        stringRepresentation += "]"
        
        return stringRepresentation
    }
}
