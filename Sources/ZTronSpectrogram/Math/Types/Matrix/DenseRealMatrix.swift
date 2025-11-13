import Accelerate

public final class DenseRealMatrix {
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
    
    
    /// This method performs the Householder decomposition of this matrix, that is, it produces an orthogonal matrix `Q` and a tridiagonal matrix `T` such that
    /// this matrix can be rewritten as the following product: `self = Q·T·Q^t`
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
            throw MatrixError.lapackError("dsytrd failed with exit code \(statusInfo)")
        }
        
        workspaceSize = -1
        dorgtr_(&triangleSpecifier, &matrixDimension, &matrix, &leadingDimension,
                &householderScalars, &workspaceQuery, &workspaceSize, &statusInfo)
        
        workspaceSize = Int32(workspaceQuery)
        workspace = [Double](repeating: 0.0, count: Int(workspaceSize))
        
        dorgtr_(&triangleSpecifier, &matrixDimension, &matrix, &leadingDimension,
                &householderScalars, &workspace, &workspaceSize, &statusInfo)
        
        guard statusInfo == 0 else {
            throw MatrixError.lapackError("dsytrd failed with exit code \(statusInfo)")
        }
        
        return HouseholderDecomposition(
            orthogonalMatrix: matrix,
            diagonal: diagonalElements,
            offDiagonal: offDiagonalElements,
            householderScalars: householderScalars,
            rowsOfDecomposedMatrix: self.rows
        )
    }

    /// Reduces this matrix to Hessenberg form, that is, it produces as an output a decomposition such that `self = P·H·P^t` where `P` is a unitary matrix, that is, `P·P^t = P^t·P = Id`, and `H` is an Hessenberg matrix, that is, it has all zeros below the first subdiagonal.
    public final func hessenbergReduction() throws -> HessenbergDecomposition {
        guard self.rows == self.columns else {
            throw MatrixError.invalidDimension("Hessenberg reduction is only defined for square matrices.")
        }
        
        // Convert row-major to column-major (NOT transpose!)
        var columnMajorMatrix = [Double](repeating: 0.0, count: self.rows * self.columns)
        var rowMajorMatrix = self.matrix
        
        vDSP_mtransD(
            &rowMajorMatrix,
            1,
            &columnMajorMatrix,
            1,
            vDSP_Length(self.rows),
            vDSP_Length(self.columns)
        )
        
        var oneBasedStartingIndex: Int32 = Int32(1)
        var oneBasedEndIndex: Int32 = Int32(self.rows)
        var tau = [Double](repeating: 0.0, count: self.rows - 1)
        var workQuery: Double = 0.0
        var lwork = Int32(-1)
        var exitCode: Int32 = 0
        
        var size: Int32 = Int32(self.rows)
        var _size: Int32 = Int32(self.rows)
        
        dgehrd_(
            &size,
            &oneBasedStartingIndex,
            &oneBasedEndIndex,
            &columnMajorMatrix,  // Now this is A in column-major, not A^T
            &_size,
            &tau,
            &workQuery,
            &lwork,
            &exitCode
        )
        
        if exitCode != 0 {
            throw MatrixError.lapackError("LAPACK dgehrd workspace query failed with exit code: \(exitCode)")
        }
        
        lwork = Int32(workQuery)
        var work = [Double](repeating: 0.0, count: Int(lwork))
        
        dgehrd_(
            &size,
            &oneBasedStartingIndex,
            &oneBasedEndIndex,
            &columnMajorMatrix,
            &_size,
            &tau,
            &work,
            &lwork,
            &exitCode
        )
        
        if exitCode != 0 {
            throw MatrixError.lapackError("LAPACK dgehrd_ failed with exit code: \(exitCode)")
        }

        var hessenberg = columnMajorMatrix
        
        for col in 0..<self.rows {
            if self.rows > col + 2 {
                for row in (col + 2)..<self.rows {
                    hessenberg[col * self.rows + row] = 0.0
                }
            }
        }
        
        var orthogonal = columnMajorMatrix
        
        lwork = -1
        dorghr_(
            &size,
            &oneBasedStartingIndex,
            &oneBasedEndIndex,
            &orthogonal,
            &_size,
            &tau,
            &workQuery,
            &lwork,
            &exitCode
        )
        
        if exitCode != 0 {
            throw MatrixError.lapackError("LAPACK dorghr workspace query failed with exit code: \(exitCode)")
        }

        lwork = Int32(workQuery)
        work = [Double](repeating: 0.0, count: Int(lwork))
        
        dorghr_(
            &size,
            &oneBasedStartingIndex,
            &oneBasedEndIndex,
            &orthogonal,
            &_size,
            &tau,
            &work,
            &lwork,
            &exitCode
        )
        
        if exitCode != 0 {
            throw MatrixError.lapackError("LAPACK dorghr_ failed with exit code: \(exitCode)")
        }

        return HessenbergDecomposition(
            hessenbergMatrix: hessenberg,
            reducerMatrix: orthogonal,
            size: self.rows,
            layout: .columnMajor
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
            throw MatrixError.invalidDimension("In matrix multiplication expected number of rows of left hand side (\(lhs.rows)) to match the number of columns of right hand side (\(rhs.columns)).")
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
    
    
    public final func column(_ column: Int) -> DenseRealMatrix {
        let ownRowsCount: vDSP_Length = .init(self.rows)
        
        let requestedColumn = Array<Double>.init(unsafeUninitializedCapacity: self.rows) { buffer, initializedCount in
            self.matrix.withUnsafeMutableBufferPointer { matrixPtr in
                vDSP_mmovD(
                    matrixPtr.baseAddress! + self.columns * column,
                    buffer.baseAddress!,
                    ownRowsCount,
                    1,
                    ownRowsCount,
                    ownRowsCount
                )
            }
            
            initializedCount = self.rows
        }
        
        return DenseRealMatrix(wrapping: requestedColumn, rows: self.rows, columns: 1)
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
    
    
    /// Returns a defensive copy of the matrix
    ///
    /// - Complexity: `O(rows * cols)` both in time and memory
    public final func getDefensiveCopyOfMatrix() -> [Double] {
        return self.matrix.vDSP_copy()
    }
    
    public final func getRows() -> Int {
        return self.rows
    }
    
    public final func getColumns() -> Int {
        return self.columns
    }
}
