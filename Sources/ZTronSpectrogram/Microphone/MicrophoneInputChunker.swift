import Foundation
import Combine
import os

/// This class has the responsibility to collect the microphone input and collect it in chunks of fixed size, specified by the `chunkSize` constructor parameter.
/// Each chunk loses the first `hopCount` samples with respect to the previous chunk, and gains `hopCount` new samples at the end.
///
/// The samples are offered to the client as an array of real numbers, that can be accessed subscribing to the publisher exposed on the interface of this class.
/// In this implementation, there are two publishers: one to publish audio chunks as they are captured, and one to send the recorded audio during the last session.
///
/// A client that wishes to use this class should subscribe to the publisher of interest.
internal final class MicrophoneInputChunker: @unchecked Sendable {
    @MainActor private let microphoneReader: MicrophoneInputReader = MicrophoneInputReader()
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
    internal let audioRecordingPublisher: AnyPublisher<[Float], Never>
        
    private let _audioChunkPublisher: PassthroughSubject<[Float], SpectrogramError>
    internal let audioChunkPublisher: AnyPublisher<[Float], SpectrogramError>
    
    private let logger = os.Logger(subsystem: "Spectrogram", category: "MicrophoneInputChunker")
    
    private let rawAudioDataLock = DispatchSemaphore(value: 1)
    private let audioRecordingLock = DispatchSemaphore(value: 1)
    private let loggerLock = DispatchSemaphore(value: 1)
    private let microphoneReaderLock = DispatchSemaphore(value: 1)
    

    @MainActor
    internal init(
        chunkSize: Int,
        hopCount: Int,
        clampToMinuteIfMemoryWarningReceived: Int = 1
    ) {
        #if DEBUG
        logger.log(level: .debug, "✓ \(String(describing: Self.self)) init")
        #endif
        
        self.chunkSize = chunkSize
        self.hopCount = hopCount
        
        self._audioRecordingPublisher = PassthroughSubject()
        self.audioRecordingPublisher = self._audioRecordingPublisher.eraseToAnyPublisher()
        
        self._audioChunkPublisher = PassthroughSubject()
        self.audioChunkPublisher = self._audioChunkPublisher.eraseToAnyPublisher()
        
        self.clampToMinuteIfMemoryWarningReceived = clampToMinuteIfMemoryWarningReceived

        self.microphoneReader
            .samplesBatchPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { @MainActor [weak self] completion in
                guard let self = self else { return }
                
                switch completion {
                    case .finished:
                        #if DEBUG
                        self.loggerLock.wait()
                        self.logger.log(level: .debug, "\(String(describing: MicrophoneInputReader.self)) sent session completion")
                        self.loggerLock.signal()
                        #endif
                    
                        self.stopRunning()
                        
                        self._audioChunkPublisher.send(completion: .finished)
                        self._audioRecordingPublisher.send(completion: .finished)
                    
                    case .failure(let error):
                        self._audioChunkPublisher.send(completion: .failure(error))
                    
                }
            }, receiveValue: { @MainActor [weak self] micSamples in
                guard let self = self else { return }
                
                self.handleMicrophoneInput(values: micSamples)
            })
            .store(in: &self.subscriptions)
        
    }
    
    
    deinit {
        #if DEBUG
        self.loggerLock.wait()
        self.logger.log(level: .debug, "✓ \(String(describing: Self.self)) deinitialising")
        self.loggerLock.signal()
        #endif
        
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                self.stopRunning()
            }
        } else {
        #if DEBUG
            self.loggerLock.wait()
            self.logger.critical("Could not stop running microphone capture because the object was deinitialised outside of the main thread.")
            self.loggerLock.signal()
        #endif
        }
        
        self._audioChunkPublisher.send(completion: .finished)
        self._audioRecordingPublisher.send(completion: .finished)
        
        self.subscriptions.forEach { $0.cancel() }
        self.audioRecording = []
        self.rawAudioData = []
    }
    
    /// Receives the inputs from the microphone and converts it in chunks of the desired size, then publishes it.
    @MainActor final func handleMicrophoneInput(values: [Float]) {
        print(#function)
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
    internal final func startRunning(shouldRecord: Bool, clearPreviousRecording: Bool = false) {
        print(#function)
        self.microphoneReaderLock.wait()
        guard !self.microphoneReader.isRunning else {
            self.microphoneReaderLock.signal()
            return
        }
        self.microphoneReaderLock.signal()

        if clearPreviousRecording {
            self.audioRecordingLock.wait()
            self.audioRecording = .init()
            self.audioRecordingLock.signal()
        }
            
        if shouldRecord {
            self.startRecording()
        }
        
        self.microphoneReaderLock.wait()
        self.microphoneReader.startRunning()
        self.microphoneReaderLock.signal()
    }
    
    
    /// Stops the microphone samples capture, if it was running. No-op otherwise.
    ///
    /// After invoking this method, the client can expect to receive an array containing all the recorded samples,
    /// if `shouldRecord` was set to `true` at the time of invokation of `startRunning(_:,_:)`.
    internal final func stopRunning() {
        print(#function)
        self.microphoneReaderLock.wait()
        Task.synchronous { @MainActor in
            self.microphoneReader.stopRunning()
        }
        self.microphoneReaderLock.signal()
            
        if self.isRecordingMicInput {
            self.stopRecording()
        }
    }
    
    
    private final func startRecording() {
        print(#function)
        guard !self.isRecordingMicInput else { return }
        
        self.audioRecordingLock.wait()
        self.audioRecording.removeAll()
        self.isRecordingMicInput = true
        self.audioRecordingLock.signal()
    }
    
    
    private final func stopRecording() {
        print(#function)
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
        #if DEBUG
        self.loggerLock.wait()
        self.logger.log(level: .debug, "\(String(describing: Self.self)) received memory warning.")
        self.loggerLock.signal()
        #endif
        
        self.microphoneReaderLock.wait()
        guard let nyquist = self.microphoneReader.getNyquistFrequency() else { return }
        self.microphoneReaderLock.signal()
        
        self.audioRecordingLock.wait()
        self.stopRunning()
        
        let samplesPerSecond = 2*Int(nyquist)
        let sampleToClampTo = self.clampToMinuteIfMemoryWarningReceived*samplesPerSecond*60

        let clampedValue = (0..<self.audioRecording.count).clamp(sampleToClampTo)
        
        /* Handle case of memory warning received before minute limit to clamp to */
        if clampedValue < sampleToClampTo {
            #if DEBUG
            self.loggerLock.wait()
            self.logger.log(level: .debug, "\(String(describing: Self.self)): Memory warning received before clamp limit reaced")
            self.loggerLock.signal()
            #endif
            
            self.audioRecording = Array(self.audioRecording[0..<self.audioRecording.count/2])
        } else {
        /* Handle case of memory warning received after minute limit to clamp to */
            #if DEBUG
            self.loggerLock.wait()
            self.logger.log(level: .debug, "\(String(describing: Self.self)): Memory warning received after clamp limit reached")
            self.loggerLock.signal()
            #endif
            
            self.audioRecording = Array(self.audioRecording[0..<sampleToClampTo])
        }
        self.audioRecordingLock.signal()
        
        self._audioRecordingPublisher.send(Array(self.audioRecording))
    }

    
    
    private final func isRecording() -> Bool {
        print(#function)
        self.audioRecordingLock.wait()

        defer {
            self.audioRecordingLock.signal()
        }
        
        return isRecordingMicInput
    }
}
