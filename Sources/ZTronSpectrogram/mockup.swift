import Foundation
import Combine

#if DEBUG
@MainActor
public func makeMicrophoneMockup() {
    let microphoneInputReader = MicrophoneInputReader.getSharedInstance()
    
    let subscription = microphoneInputReader
                            .samplesBatchPublisher
                            .receive(on: RunLoop.main)
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
                .audioChunkPublisher
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
#endif
