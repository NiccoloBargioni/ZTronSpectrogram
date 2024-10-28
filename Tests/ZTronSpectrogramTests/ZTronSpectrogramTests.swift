import Testing
import Foundation
import Combine
@testable import ZTronSpectrogram

@MainActor @Test func testFFT() async throws {
    let fftCalc = FFTCalculator(chunksProvider: MicrophoneInputChunker(chunkSize: 1024, hopCount: 16))
}
