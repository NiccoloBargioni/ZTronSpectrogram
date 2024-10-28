import Foundation
import Combine

#if DEBUG
@MainActor
public func makeMicrophoneMockup() {
    let microphoneInputReader = MicrophoneInputReader()
    
    let subscription = microphoneInputReader
                            .samplesBatchPublisher
                            .receive(on: DispatchQueue.main)
                            .filter {
                                $0.count > 0
                            }
                            .sink { completion in
                                switch completion {
                                case .finished:
                                    print("Microphone finished publishing samples")
                                    
                                case .failure(let error):
                                    print("Microphone capture failed with error: \(error.what)")
                                }
                                
                            } receiveValue: { batch in
                                precondition(batch.count == 1024)
                            }
    
    microphoneInputReader.startRunning()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { @MainActor in
        microphoneInputReader.stopRunning()
        subscription.cancel()
    }

}


@MainActor
public func makeChunkerMockup() {
    let chunker = MicrophoneInputChunker(
        chunkSize: 2048,
        hopCount: 4
    )
    
    let chunksSubscription = chunker
                .signalChunksPublisher
                .sink { completion in
                    switch completion {
                        case .finished:
                            print("Won't publish any more chunks")
                            
                        case .failure(let error):
                            print("Failed with error \(error.what)")
                    }
                } receiveValue: { chunk in
                    print("Chunk size: \(chunk.count)")
                }
    
    chunker.startRunning(shouldRecord: false)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
        chunker.stopRunning()
        chunksSubscription.cancel()
    }

}


@MainActor
public func makeFFTMockup() {
    let chunker = MicrophoneInputChunker(chunkSize: 1024, hopCount: 16)
    let fftCalc = FFTCalculator(chunksProvider: chunker)
    
    let fftSubscription = fftCalc
        .frequencySnapshotProvider
                .sink { completion in
                    switch completion {
                        case .finished:
                            print("Won't publish any more chunks")
                            
                        case .failure(let error):
                            print("Failed with error \(error.what)")
                    }
                } receiveValue: { chunk in
                    print("Received chunks")
                }
    
    chunker.startRunning(shouldRecord: false)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
        chunker.stopRunning()
        fftSubscription.cancel()
    }

}
#endif


