import Foundation
import Combine

internal protocol SignalChunker: Sendable {
    var signalChunksPublisher: AnyPublisher<[Float], SpectrogramError> { get }
}
