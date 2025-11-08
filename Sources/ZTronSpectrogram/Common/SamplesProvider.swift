import Foundation
import Combine

/// An object implementing this protocol provides sequences of samples from an audio source.
/// There is no guarantee of the size of each batch, as in, even consecutive batches could have different length.
public protocol SamplesProvider {
    var isRunning: Bool { get }
    
    /// This valiable is used to publish samples of an audio signal.
    var samplesBatchPublisher: AnyPublisher<[Float], SpectrogramError> { get }
    
    /// When this method is invoked, this implementation starts publishing samples, if not running already.
    func startRunning() -> Void
    
    /// When this method is invoked, this implementation stops publishing samples.
    func stopRunning() -> Void
    
    /// Returns the Nyquist frequency of the signal whose samples are being provided.
    /// If such information was not available, then the Nyquist frequency of the currently active microphone (or default one if none is active), with the current AVAudioSession configuration is provided.
    func getNyquistFrequency() -> Float
}
