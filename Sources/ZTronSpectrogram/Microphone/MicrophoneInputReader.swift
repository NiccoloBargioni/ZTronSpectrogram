import Foundation
import Accelerate
@preconcurrency import AVFoundation
import Combine


/// A singleton class that handles low-level interaction with the device's microphone.
/// It provides access to the recorded samples through Combine framework, providing a certain number of samples at a time.
///
/// Operative tests on a microphone with Nyquist frequency of 22100 Hz usually produce 1024 samples at a time but the number of samples may
/// have very small variations (usually by about four samples) but such occurrence is uncommon. Further tests may be required
internal final class MicrophoneInputReader: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate, @unchecked Sendable {
    @MainActor private static var sharedInstance: MicrophoneInputReader?
    private let captureSession = AVCaptureSession()
    private let audioOutput = AVCaptureAudioDataOutput()
    
    @MainActor internal var isRunning: Bool {
        return self.captureSession.isRunning
    }
    
    private var convertedTimeSamples = [Float].init()
    
    private var nyquistFrequency: Float? = nil
    
    private let captureQueue = DispatchQueue(label: "captureQueue",
                                     qos: .userInitiated,
                                     attributes: [],
                                     autoreleaseFrequency: .workItem)
    
    private let sessionQueue = DispatchQueue(label: "sessionQueue",
                                     attributes: [],
                                     autoreleaseFrequency: .workItem)
    
    private let samplesBatch: CurrentValueSubject<[Float], SpectrogramError> = .init([])
    internal let samplesBatchPublisher: AnyPublisher<[Float], SpectrogramError>
    
    private let convertedTimeSamplesLock: DispatchSemaphore = .init(value: 1)
    private let nyquistFrequencyLock: DispatchSemaphore = .init(value: 1)
    
    override private init() {
        self.samplesBatchPublisher = self.samplesBatch.eraseToAnyPublisher()
        super.init()
        self.audioOutput.setSampleBufferDelegate(self, queue: self.captureQueue)
        self.configureCaptureSession()
        audioOutput.setSampleBufferDelegate(self, queue: captureQueue)
    }
    
    
    @MainActor public static func getSharedInstance() -> MicrophoneInputReader {
        if self.sharedInstance == nil {
            self.sharedInstance = MicrophoneInputReader()
        }
        
        return self.sharedInstance!
    }
    
    
    nonisolated internal final func startRunning() {
        if !self.captureSession.isRunning {
            sessionQueue.async {
                Task {
                    await MainActor.run {
                        if AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
                            MicrophoneInputReader.sharedInstance?.captureSession.startRunning()
                        }
                    }
                }
            }
        }
    }
    
    
    nonisolated internal final func stopRunning() {
        if self.captureSession.isRunning {
            sessionQueue.async {
                Task {
                    await MainActor.run {
                        MicrophoneInputReader.sharedInstance?.captureSession.stopRunning()
                    }
                }
            }
        }
    }
    
    internal final func getNyquistFrequency() -> Float? {
        self.nyquistFrequencyLock.wait()
        
        defer {
            self.nyquistFrequencyLock.signal()
        }
        
        return self.nyquistFrequency
    }
    
    
    //MARK: Microphone permission configuration
    private final func configureCaptureSession() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized:
                    break
            case .notDetermined:
                sessionQueue.suspend()
                AVCaptureDevice.requestAccess(for: .audio,
                                              completionHandler: { granted in
                    if !granted {
                        self.samplesBatch.send(
                            completion: .failure(
                                SpectrogramError(
                                    kind: .unauthorized,
                                    what: "Please grant Zombietron access to your device's microphone to render spectrogram from live microphone."
                                )
                            )
                        )

                    } else {
                        self.configureCaptureSession()
                        self.sessionQueue.resume()
                    }
                })
                return
            default:
            self.samplesBatch.send(
                completion: .failure(
                    SpectrogramError(
                        kind: .unauthorized,
                        what: "Please grant Zombietron access to your device's microphone to render spectrogram from live microphone."
                    )
                )
            )
        }

        captureSession.beginConfiguration()
        
        if captureSession.canAddOutput(audioOutput) {
            captureSession.addOutput(audioOutput)
        } else {
            self.samplesBatch.send(
                completion: .failure(
                    SpectrogramError(
                        kind: .audioOutputException,
                        what: "Zombietron was unable to attach the module to process microphone data to the AVCaptureSession."
                    )
                )
            )
        }
        
        guard
            let microphone = AVCaptureDevice.default(.builtInMicrophone,
                                                     for: .audio,
                                                     position: .unspecified),
            let microphoneInput = try? AVCaptureDeviceInput(device: microphone)
        else {
            self.samplesBatch.send(
                completion: .failure(
                    SpectrogramError(
                        kind: .deviceError,
                        what: "Zombietron was unable to create an audio input model for the microphone."
                    )
                )
            )
            
            return
        }
        
        if captureSession.canAddInput(microphoneInput) {
            captureSession.addInput(microphoneInput)
        }
        
        captureSession.commitConfiguration()
    }
    
    //MARK: Capture audio samples
    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {

        var audioBufferList = AudioBufferList()
        var blockBuffer: CMBlockBuffer?
  
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: &audioBufferList,
            bufferListSize: MemoryLayout.stride(ofValue: audioBufferList),
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
            blockBufferOut: &blockBuffer)
        
        guard let data = audioBufferList.mBuffers.mData else {
            return
        }

        self.nyquistFrequencyLock.wait()
        if nyquistFrequency == nil {
            let duration = Float(CMSampleBufferGetDuration(sampleBuffer).value)
            let timescale = Float(CMSampleBufferGetDuration(sampleBuffer).timescale)
            let numsamples = Float(CMSampleBufferGetNumSamples(sampleBuffer))
            nyquistFrequency = 0.5 / (duration / timescale / numsamples)
        }
        self.nyquistFrequencyLock.signal()
        
        let actualSampleCount = CMSampleBufferGetNumSamples(sampleBuffer)
        
        let ptr = data.bindMemory(to: Int16.self, capacity: actualSampleCount)
        let buf = UnsafeBufferPointer(start: ptr, count: actualSampleCount)
        
        self.convertedTimeSamplesLock.wait()
        if actualSampleCount > self.convertedTimeSamples.count {
            self.convertedTimeSamples.append(contentsOf: [Float].init(repeating: 0, count: actualSampleCount - self.convertedTimeSamples.count))
        } else {
            if actualSampleCount < convertedTimeSamples.count {
                self.convertedTimeSamples.removeLast(convertedTimeSamples.count - actualSampleCount)
            }
        }
        
        vDSP.convertElements(of: Array(buf), to: &self.convertedTimeSamples)
        self.convertedTimeSamplesLock.signal()
        
        self.samplesBatch.send(Array(convertedTimeSamples))
    }
    
    deinit {
        self.captureSession.stopRunning()
        self.samplesBatch.send(completion: .finished)
    }
}
