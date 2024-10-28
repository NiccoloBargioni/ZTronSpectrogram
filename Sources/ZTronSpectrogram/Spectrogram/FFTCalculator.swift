import Foundation
import os
import Accelerate
@preconcurrency import Combine


internal final class FFTCalculator: @unchecked Sendable {
    private let frequency: [Float] = .init()
    private var subscriptions: Set<AnyCancellable> = .init()
    private let fft = FFT(windowSize: 1024)
    private static let logger: Logger = .init(subsystem: "Spectrogram", category: "FFT Calculator")

    private let _frequencySnapshotProvider: PassthroughSubject<[Float], SpectrogramError> = .init()
    internal let frequencySnapshotProvider: AnyPublisher<[Float], SpectrogramError>
    
    private let frequencyLock = DispatchSemaphore(value: 1)
    
    @MainActor
    internal init(chunksProvider: any SignalChunker) {
        self.frequencySnapshotProvider = self._frequencySnapshotProvider.eraseToAnyPublisher()
        
        chunksProvider
            .signalChunksPublisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                    case .finished:
                    self._frequencySnapshotProvider.send(completion: .finished)
                    
                    case .failure:
                        self._frequencySnapshotProvider.send(completion: completion)
                }
            } receiveValue: { @MainActor [weak self] timeChunk in
                guard let self else { return }
                self.handleChunkReceived(timeChunk)
            }
            .store(in: &self.subscriptions)
    }
    
    
    @MainActor
    private final func handleChunkReceived(_ theSamples: [Float]) {
        self.frequencyLock.wait()
        // Fake implementation
        
        var realP = Array(theSamples)
        var imagP = [Float].init(repeating: 0, count: theSamples.count)
        
        realP.withUnsafeMutableBufferPointer { realPtr in
            imagP.withUnsafeMutableBufferPointer { imagPtr in
                let complexSignal = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
                let _ = fft.transform(samples: complexSignal)
            }
        }


        
        
        self._frequencySnapshotProvider.send(frequency)
        self.frequencyLock.signal()
    }
    
    deinit {
        self.subscriptions.forEach {
            $0.cancel()
        }
    }
    
}
