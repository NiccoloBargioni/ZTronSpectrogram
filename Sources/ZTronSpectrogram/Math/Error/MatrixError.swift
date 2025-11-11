import Foundation

public enum MatrixError: Error {
    case invalidDimension(String)
    case lapackError(String)
}
