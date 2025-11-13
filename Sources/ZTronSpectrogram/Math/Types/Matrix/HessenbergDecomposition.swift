import Accelerate

public final class HessenbergDecomposition {
    private let hessenbergMatrix: DenseRealMatrix
    private let reducerMatrix: DenseRealMatrix
    private let layout: MatrixLayout
    
    internal init(
        hessenbergMatrix: [Double],
        reducerMatrix: [Double],
        size: Int,
        layout: MatrixLayout
    ) {
        self.hessenbergMatrix = DenseRealMatrix(wrapping: hessenbergMatrix, rows: size, columns: size)
        self.reducerMatrix = DenseRealMatrix(wrapping: reducerMatrix, rows: size, columns: size)
        self.layout = layout
    }
    
    public final func getHessenbergMatrix() -> DenseRealMatrix {
        return self.hessenbergMatrix
    }
    
    public final func getReducerMatrix() -> DenseRealMatrix {
        return self.reducerMatrix
    }
    
    public final func getMatrixLayout() -> MatrixLayout {
        return self.layout
    }
    
    /// It computes the eigenvectors of the matrix `A = schurVectors·schurCanonicalForm·schurVectors^t`, storing them in a complex dense matrix in row-major order,
    /// meaning that the eigenvectors are stored as columns of such matrix.
    ///
    /// - Note: Can be kinda numerically unstable, tests show that the error can be around 10e-7.
    internal static func computeEigenvectorsFromSchur(
        schurCanonicalForm: inout [Double],
        schurVectors: inout [Double],
        eigenvalues: SplitDoubleComplexArray
    ) throws -> DenseComplexMatrix {
        guard floor(sqrt(Double(schurCanonicalForm.count))) == ceil(sqrt(Double(schurCanonicalForm.count))) else {
            throw MatrixError.invalidDimension("Expected input to be a square matrix.")
        }
        
        var size = Int32(sqrt(Double(schurCanonicalForm.count)))
        let count = Int(size)
        
        var side: Int8 = 82 // R
        var howmny: Int8 = 66 // B
        var select = [__CLPK_logical](repeating: 0, count: count)
        
        var schurMatrixLeadingDimension = size
        var leadingDimensionOfVL = size
        var leadingDimensionOfSchurVectors = size
        var columnsCountOfSchurVectors = size
        
        /// This is used for output. After the execution of `dtrevc_`, this contains the number of columns actually used to store eigenvectors
        var columnsUsedForEigenvectors: Int32 = 0
        var exitCode: Int32 = 0
        
        /// Required per netlib.org/lapack documentation to be an array of size 3N, it's an output parameter
        var work = [Double](repeating: 0.0, count: Int(3 * size))
        
        // An empty matrix, can't pass nil because it causes EXC_BAD_ACCESS but it's not used for side == 'R' so it's a dummy array.
        var vl = [Double](repeating: 0.0, count: count * count)
        
        
        /// as per https://www.netlib.org/lapack/explore-html/da/d6a/group__trevc_gaa133930047d3b8fb4958ac4c6d908bb7.html
        /// VR must contain an N-by-N matrix Q (usually the orthogonal matrix Q of Schur vectors returned by DHSEQR).
        ///
        /// On output, when HOWMNY == 'B', it contains the eigenvectors of the matrix `A = V·T·V^t`
        /// where `T` is a matrix in Schur canonical form and `V` the matrix of Schur vectors.
        var vr = schurVectors
        
        dtrevc_(
            &side,
            &howmny,
            &select,
            &size,
            &schurCanonicalForm,
            &schurMatrixLeadingDimension,
            &vl,
            &leadingDimensionOfVL,
            &vr,
            &leadingDimensionOfSchurVectors,
            &columnsCountOfSchurVectors,
            &columnsUsedForEigenvectors,
            &work,
            &exitCode
        )
        
        if exitCode < 0 {
            throw MatrixError.lapackError("dtrevc_: the \(-exitCode)-th parameter had an illegal value.")
        }
        
        let realp = UnsafeMutablePointer<Double>.allocate(capacity: count * count)
        let imagp = UnsafeMutablePointer<Double>.allocate(capacity: count * count)
        
        realp.initialize(repeating: 0.0, count: count * count)
        imagp.initialize(repeating: 0.0, count: count * count)
                
        var i = 0
        while i < count {
            if i + 1 < count && abs(schurCanonicalForm[i * count + (i + 1)]) > 1e-10 {
                for j in 0..<count {
                    let realPart = vr[i * count + j]
                    let imagPart = vr[(i + 1) * count + j]
                    
                    realp[j * count + i] = realPart
                    imagp[j * count + i] = imagPart
                    
                    realp[j * count + (i + 1)] = realPart
                    imagp[j * count + (i + 1)] = -imagPart
                }
                i += 2
            } else {
                for row in 0..<count {
                    realp[row * count + i] = vr[i * count + row]
                    imagp[row * count + i] = 0.0
                }
                i += 1
            }
        }
        
        let complexArray = DSPDoubleSplitComplex(
            realp: realp,
            imagp: imagp
        )
                
        return DenseComplexMatrix(
            wrapping: SplitDoubleComplexArray(array: complexArray, size: count * count),
            rows: count,
            columns: count
        )
    }
    
    
    /// It computes the eigenvectors of the matrix `A = P·H·P^t`, storing them in a complex dense matrix in row-major order,
    /// meaning that the eigenvectors are stored as columns of such matrix.
    public final func getEigenvectorDecomposition() throws -> EigenvectorDecompositionComplex {
        let size = self.hessenbergMatrix.getRows()
        
        
        var startingIndex = Int32(1)
        var endIndex = Int32(size)
        
        let eigenvaluesReal = UnsafeMutablePointer<Double>.allocate(capacity: size)
        let eigenvaluesImag = UnsafeMutablePointer<Double>.allocate(capacity: size)

        /// If COMPZ = 'I', on entry Z need not be set and on exit,
        /// if INFO = 0, Z contains the orthogonal matrix Z of the Schur
        /// vectors of H.
        var matrixOfSchurVectors = [Double](repeating: 0.0, count: size * size)
        
        var leadingDimensionOfSchurMatrix = Int32(size)
        var job: Int8 = 83  // S
        var compz: Int8 = 73 // I
        
        for i in 0..<size {
            matrixOfSchurVectors[i * size + i] = 1.0
        }
        
        var workQuery: Double = 0.0
        var lwork = Int32(-1)
        var exitCode: Int32 = 0
        var orderOfHessenbergMatrix = __CLPK_integer(size)
        var leadingDimensionOfHessenberg = __CLPK_integer(size)
        
        var hessenberg = self.hessenbergMatrix.getDefensiveCopyOfMatrix()
        
        /// It is assumed that H is already upper triangular in rows
        /// and columns 1:ILO-1 and IHI+1:N. ILO and IHI are normally
        /// set by a previous call to DGEBAL, and then passed to ZGEHRD
        /// when the matrix output by DGEBAL is reduced to Hessenberg
        /// form. Otherwise ILO and IHI should be set to 1 and N
        /// respectively.  If N > 0, then 1 <= ILO <= IHI <= N.
        /// If N = 0, then ILO = 1 and IHI = 0.
        dhseqr_(
            &job,
            &compz,
            &orderOfHessenbergMatrix,
            &startingIndex,
            &endIndex,
            &hessenberg,
            &leadingDimensionOfHessenberg,
            eigenvaluesReal,
            eigenvaluesImag,
            &matrixOfSchurVectors,
            &leadingDimensionOfSchurMatrix,
            &workQuery,
            &lwork,
            &exitCode
        )

        if exitCode != 0 {
            if exitCode > 0 {
                throw MatrixError.lapackError("dhseqr_ failed to compute the \(exitCode)th eigenvector.")
            } else {
                throw MatrixError.lapackError("The \(-exitCode)th parameter to dhseqr_ was illegal.")
            }
        }

        lwork = Int32(workQuery)
        var work = [Double](repeating: 0.0, count: Int(lwork))
        

        hessenberg = self.hessenbergMatrix.getDefensiveCopyOfMatrix()
        matrixOfSchurVectors = [Double](repeating: 0.0, count: size * size)
        for i in 0..<size {
            matrixOfSchurVectors[i * size + i] = 1.0
        }

        
        dhseqr_(
            &job,
            &compz,
            &orderOfHessenbergMatrix,
            &startingIndex,
            &endIndex,
            &hessenberg,
            &leadingDimensionOfHessenberg,
            eigenvaluesReal,
            eigenvaluesImag,
            &matrixOfSchurVectors,
            &leadingDimensionOfSchurMatrix,
            &work,
            &lwork,
            &exitCode
        )

        if exitCode != 0 {
            if exitCode > 0 {
                throw MatrixError.lapackError("dhseqr_ failed to compute the \(exitCode)th eigenvector.")
            } else {
                throw MatrixError.lapackError("The \(-exitCode)th parameter to dhseqr_ was illegal.")
            }
        }

        let eigenvalues = SplitDoubleComplexArray(
            array: DSPDoubleSplitComplex(realp: eigenvaluesReal, imagp: eigenvaluesImag),
            size: size
        )
        
        let hessenbergReducer = self.reducerMatrix.getDefensiveCopyOfMatrix()
        
        var VMatrixOfSchur = [Double](repeating: 0.0, count: size * size)
        cblas_dgemm(
            CblasColMajor,
            CblasNoTrans,
            CblasNoTrans,
            Int32(size),
            Int32(size),
            Int32(size),
            1.0,
            hessenbergReducer,
            Int32(size),
            matrixOfSchurVectors,
            Int32(size),
            0.0,
            &VMatrixOfSchur,
            Int32(size)
        )

        
        let eigenvectors = try Self.computeEigenvectorsFromSchur(
            schurCanonicalForm: &hessenberg,
            schurVectors: &VMatrixOfSchur,
            eigenvalues: eigenvalues
        )
        
        return EigenvectorDecompositionComplex(
            matrixOfEigeinvectors: eigenvectors,
            eigenvalues: eigenvalues,
            layout: .rowMajor
        )
    }
}
