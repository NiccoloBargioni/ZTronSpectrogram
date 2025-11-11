import Foundation

public final class HouseholderDecomposition {
    private let diagonal: [Double]
    private let offDiagonal: [Double]
    private let householderScalars: [Double]
    private let orthogonalMatrix: [Double]
    
    public init(
        orthogonalMatrix: [Double],
        diagonal: [Double],
        offDiagonal: [Double],
        householderScalars: [Double]
    ) {
        self.diagonal = diagonal
        self.offDiagonal = offDiagonal
        self.householderScalars = householderScalars
        self.orthogonalMatrix = orthogonalMatrix
    }
    
    public func getOrthogonalMatrix() -> [Double] {
        return self.orthogonalMatrix
    }
    
    public func getDiagonal() -> [Double] {
        return self.diagonal
    }
    
    public func getOffDiagonal() -> [Double] {
        return self.offDiagonal
    }
    
    public func getHouseholderScalars() -> [Double] {
        return self.householderScalars
    }

}
