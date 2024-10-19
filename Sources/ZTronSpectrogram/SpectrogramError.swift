public struct SpectrogramError: Error {
    enum ErrorMode {
        //MARK: Tied to input
        case unauthorized
        case audioOutputException
        case deviceError
        
        //MARK: Tied to memory
        case imageBufferAllocationError
        case imageFormatCreationError
        case cgImageCreationError
        
        //MARK: Tied to configuration
        case spectrogramConfigException
        
        //MARK: Miscellaneous
        case fftSetupException
    }

    let kind: ErrorMode
    let what: String
}
