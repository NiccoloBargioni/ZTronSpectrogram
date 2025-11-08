import Foundation

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
