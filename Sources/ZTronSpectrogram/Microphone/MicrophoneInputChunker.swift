import Foundation
import Combine

/// This class has the responsibility to collect the microphone input and collect it in chunks of fixed size, specified by the `chunkSize` constructor parameter.
/// Each chunk loses the first `hopCount` samples with respect to the previous chunk, and gains `hopCount` new samples at the end.
///
/// The samples are offered to the client as an array of real numbers, that can be accessed subscribing to the publisher exposed on the interface of this class.
/// In this implementation, there are two publishers: one to publish audio chunks as they are captured, and one to send the recorded audio during the last session.
///
/// A client that wishes to use this class should subscribe to the publisher of interest.
internal final class MicrophoneInputChunker: @unchecked Sendable {
    @MainActor private var microphoneReader: MicrophoneInputReader = MicrophoneInputReader.getSharedInstance()
    private let clampToMinuteIfMemoryWarningReceived: Int
    
    private let chunkSize: Int
    private let hopCount: Int
    
    private var rawAudioData = [Float]()
    private var audioRecording = [Float]()
    
    private var microphoneInputQueue = DispatchQueue(
        label: "microphoneInputProcessingQueue",
        qos: .userInitiated,
        autoreleaseFrequency: .workItem
    )
    
    private var isRecordingMicInput: Bool = false

    private var subscriptions: Set<AnyCancellable> = Set<AnyCancellable>()
        
    private let _audioRecordingPublisher: PassthroughSubject<[Float], Never>
    private let audioRecordingPublisher: AnyPublisher<[Float], Never>
        
    private let _audioChunkPublisher: PassthroughSubject<[Float], SpectrogramError>
    private let audioChunkPublisher: AnyPublisher<[Float], SpectrogramError>
    
    
    private var rawAudioDataLock = DispatchSemaphore(value: 1)
    private var audioRecordingLock = DispatchSemaphore(value: 1)

    
    private init(
        chunkSize: Int,
        hopCount: Int,
        clampToMinuteIfMemoryWarningReceived: Int = 1
    ) {
        print("MicrophoneInputManager init")
        
        self.chunkSize = chunkSize
        self.hopCount = hopCount
        
        self._audioRecordingPublisher = PassthroughSubject()
        self.audioRecordingPublisher = self._audioRecordingPublisher.eraseToAnyPublisher()
        
        self._audioChunkPublisher = PassthroughSubject()
        self.audioChunkPublisher = self._audioChunkPublisher.eraseToAnyPublisher()
        
        self.clampToMinuteIfMemoryWarningReceived = clampToMinuteIfMemoryWarningReceived

        microphoneReader
            .samplesBatchPublisher
            .receive(on: self.microphoneInputQueue)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                switch completion {
                    case .finished:
                        print("Microphone stopped publishing input data")
                    
                    case .failure(let error):
                        self._audioChunkPublisher.send(completion: .failure(error))
                    
                }
            }, receiveValue: { [weak self] micSamples in
                guard let self = self else { return }
                
                self.handleMicrophoneInput(values: micSamples)
            })
            .store(in: &self.subscriptions)
        
    }
    
    
    deinit {
        print("deinit MicrophoneInputManager")
                
        self.stopRunning()
        self._audioChunkPublisher.send(completion: .finished)
        self._audioRecordingPublisher.send(completion: .finished)
        
        self.subscriptions.forEach { $0.cancel() }
        self.audioRecording = []
        self.rawAudioData = []
        
    }
    
    /// Receives the inputs from the microphone and converts it in chunks of the desired size, then publishes it.
    final func handleMicrophoneInput(values: [Float]) {
        audioRecordingLock.wait()
        if self.isRecordingMicInput {
            self.audioRecording.append(contentsOf: values)
        }
        audioRecordingLock.signal()
        
        rawAudioDataLock.wait()
        
        if self.rawAudioData.count < self.chunkSize * 2 {
            rawAudioData.append(contentsOf: values)
        }
        
        while self.rawAudioData.count >= self.chunkSize {
            let dataToProcess = Array(self.rawAudioData[0 ..< self.chunkSize])
            
            self._audioChunkPublisher.send(dataToProcess)
            self.rawAudioData.removeFirst(self.hopCount)
        }
                
        rawAudioDataLock.signal()
    }
    
    
    /// Starts to receive samples from the microphone. If the microphone capture was already running, nothing happens.
    /// After invoking this method, the client can expect to start receiving chunks of audio samples from the microphone.
    ///
    /// - Parameter shouldRecord: If set to `true`, upon completion, `audioRecordingPublisher` sends all the samples
    /// received between the call of this method and the next call to `stopRunning()`.
    /// - Parameter clearPreviousRecording: if set to `true`, the previously recorded samples are discarded, otherwise new samples are appended
    /// to the previous recording, if `shouldRecord == true`.
    @MainActor
    private final func startRunning(shouldRecord: Bool, clearPreviousRecording: Bool = false) {
        guard !self.microphoneReader.isRunning else { return  }
                
        if clearPreviousRecording {
            self.audioRecordingLock.wait()
            self.audioRecording = .init()
            self.audioRecordingLock.signal()
        }
            
        if shouldRecord {
            self.startRecording()
        }
        
        self.microphoneReader.startRunning()
    }
    
    
    /// Stops the microphone samples capture, if it was running. No-op otherwise.
    ///
    /// After invoking this method, the client can expect to receive an array containing all the recorded samples,
    /// if `shouldRecord` was set to `true` at the time of invokation of `startRunning(_:,_:)`.
    private final func stopRunning() {
        Task {
            await MainActor.run {
                self.microphoneReader.stopRunning()
            }
        }
            
        if self.isRecordingMicInput {
            self.stopRecording()
        }
    }
    
    
    private final func startRecording() {
        guard !self.isRecordingMicInput else { return }
        
        self.audioRecordingLock.wait()
        self.audioRecording.removeAll()
        self.isRecordingMicInput = true
        self.audioRecordingLock.signal()
    }
    
    
    private final func stopRecording() {
        guard self.isRecordingMicInput else { return }
        
        self.audioRecordingLock.wait()
        self.isRecordingMicInput = false
        self._audioRecordingPublisher.send(Array(self.audioRecording))
        self.audioRecordingLock.signal()
    }
    
    
    /// When memory is running low, you can invoke this method to free some.
    ///
    /// When you create an instance of this class, you can specify a `clampToMinuteIfMemoryWarningReceived` parameter that prescribes to
    /// only keep the first specified amount of minutes from the recorded audio when a memory warning is received. If at the moment of invokation,
    /// the recorded samples are less than this threshold, the size of the recording is halved, otherwise, it is reduced to a number of samples corresponding to
    /// `clampToMinuteIfMemoryWarningReceived` minutes. Default is 1 minute worth of samples.
    ///
    /// This implementation also stops the audio capture, to save memory.
    @MainActor
    private final func handleMemoryWarningReceived() {
        print("Did receive memory warning @ MicrophoneInputManager")
        
        guard let nyquist = self.microphoneReader.getNyquistFrequency() else { return }

        self.audioRecordingLock.wait()
        self.stopRunning()
        
        let samplesPerSecond = 2*Int(nyquist)
        let sampleToClampTo = self.clampToMinuteIfMemoryWarningReceived*samplesPerSecond*60

        let clampedValue = (0..<self.audioRecording.count).clamp(sampleToClampTo)
        
        /* Handle case of memory warning received before minute limit to clamp to */
        if clampedValue < sampleToClampTo {
            print("Memory warning received before clamp limit reaced")
            self.audioRecording = Array(self.audioRecording[0..<self.audioRecording.count/2])
        } else {
        /* Handle case of memory warning received after minute limit to clamp to */
            print("Memory warning received after clamp limit reaced")
            self.audioRecording = Array(self.audioRecording[0..<sampleToClampTo])
        }
        self.audioRecordingLock.signal()
        
        self._audioRecordingPublisher.send(Array(self.audioRecording))
    }

    
    
    private final func isRecording() -> Bool {
        self.audioRecordingLock.wait()

        defer {
            self.audioRecordingLock.signal()
        }
        
        return isRecordingMicInput
    }
}