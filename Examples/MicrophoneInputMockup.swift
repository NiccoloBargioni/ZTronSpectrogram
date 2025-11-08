import Foundation


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
                                // TODO: Handle whatever you'd like to do with your samples
                            }
    
    microphoneInputReader.startRunning()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { @MainActor in
        microphoneInputReader.stopRunning()
        subscription.cancel()
    }

}
