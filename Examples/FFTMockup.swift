import Foundation
import Combine


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


