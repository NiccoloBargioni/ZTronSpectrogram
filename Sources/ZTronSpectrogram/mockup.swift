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
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
        microphoneInputReader.stopRunning()
        subscription.cancel()
    }

}
#endif
