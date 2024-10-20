import Testing
import Foundation
import Combine
@testable import ZTronSpectrogram

@MainActor @Test func testMicrophoneInput() async throws {
    let microphoneInputReader = MicrophoneInputReader.getSharedInstance()
    
    let subscription = microphoneInputReader
                            .samplesBatchPublisher
                            .receive(on: RunLoop.main)
                            .sink { _ in
                                
                            } receiveValue: { batch in
                                #expect(batch.count == 1024)
                            }
    
    microphoneInputReader.startRunning()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
        microphoneInputReader.stopRunning()
        subscription.cancel()
    }
}
