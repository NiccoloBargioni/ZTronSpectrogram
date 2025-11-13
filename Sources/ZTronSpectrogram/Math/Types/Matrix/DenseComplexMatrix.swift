import Accelerate

public final class DenseComplexMatrix: CustomStringConvertible {
    public var description: String {
        return self.toString()
    }
    
    private let matrix: SplitDoubleComplexArray
    private let rows: Int
    private let columns: Int

    public init(wrapping: SplitDoubleComplexArray, rows: Int, columns: Int) {
        self.matrix = wrapping
        self.rows = rows
        self.columns = columns
        
    }

    subscript(index: Int) -> SplitDoubleComplexArray {
        return SplitDoubleComplexArray(
            array: self.matrix[ index*self.columns...(index + 1)*self.columns - 1],
            size: self.columns
        )
    }
    
    
    private final func toString() -> String {
        var stringRepresentation = "[\n"
        
        for i in 0..<self.rows {
            var rowStringRepresentation = "  ["
            for j in 0..<self.columns {
                rowStringRepresentation += self.matrix[i * self.columns + j].description
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
    
    public final func column(_ column: Int) -> DenseComplexMatrix {
        let requestedColumn = self.matrix.takeSamples(
            stride: self.columns,
            initialOffset: column
        )
        
        return DenseComplexMatrix(
            wrapping: requestedColumn,
            rows: self.rows,
            columns: 1
        )
    }
}
