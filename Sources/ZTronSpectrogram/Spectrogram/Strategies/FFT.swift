import Accelerate
import os

internal final class FFT: FFTStrategyDecorator, @unchecked Sendable {
    private let windowSize: Int
    private static let logger: Logger = .init(subsystem: "com.zombietron.ztronspectrogram", category: "FFT")
    
    
    private var fftRealBuffer: [Float]
    private var fftImagBuffer: [Float]
    private var inputRealParts: [Float]
    private var inputImagParts: [Float]
    private var frequencyDomainBuffer: [Float]
    private var fftConfig: FFTSetup
    
    private var samplesRealpCopy: [Float]
    private var samplesImagpCopy: [Float]
    
    private let fftRealBufferLock = DispatchSemaphore(value: 1)
    private let fftImagBufferLock = DispatchSemaphore(value: 1)
    private let inputRealPartsLock = DispatchSemaphore(value: 1)
    private let inputImagPartsLock = DispatchSemaphore(value: 1)
    private let samplesRealpCopyLock = DispatchSemaphore(value: 1)
    private let samplesImagpCopyLock = DispatchSemaphore(value: 1)
    private let frequencyDomainBufferLock = DispatchSemaphore(value: 1)
    private let fftConfigLock = DispatchSemaphore(value: 1)
    private static let loggerLock = DispatchSemaphore(value: 1)
    
    
    internal init(windowSize: Int) {
        assert(windowSize > 0)
        
        #if DEBUG
        Self.loggerLock.wait()
        let logSize = log2(Float(windowSize))
        
        if logSize != ceilf(logSize) {
            Self.logger.warning("Prefer windows sizes that are power of two!!")
        }
        
        Self.loggerLock.signal()
        #endif
        
        self.fftRealBuffer = [Float].init(repeating: 0, count: windowSize)
        self.inputRealParts = [Float].init(repeating: 0, count: windowSize)
        
        self.fftImagBuffer = [Float].init(repeating: 0, count: windowSize)
        self.inputImagParts = [Float].init(repeating: 0, count: windowSize)
        
        self.frequencyDomainBuffer = [Float].init(repeating: 0, count: windowSize)

        
        self.samplesRealpCopy = [Float].init(repeating: 0, count: windowSize)
        self.samplesImagpCopy = [Float].init(repeating: 0, count: windowSize)
        
        self.windowSize = windowSize
        
        let log2n = vDSP_Length(log2( Float( windowSize ) ))

        guard let fft = vDSP_create_fftsetup(log2n, 2) else {
            Self.loggerLock.wait()
            Self.logger.error("Unable to create FFT Setup")
            Self.loggerLock.signal()
                
            fatalError()
        }
        
        self.fftConfig = fft
    }
    
    internal final func transform(samples: DSPSplitComplex) -> DSPSplitComplex {
        var hammingWindow = [Float](repeating: 0, count: windowSize)
        vDSP_hamm_window(&hammingWindow, vDSP_Length(windowSize), 0)

        self.samplesRealpCopyLock.wait()
        vDSP_vmul(
            samples.realp,
            1,
            hammingWindow,
            1,
            &self.samplesRealpCopy,
            1,
            vDSP_Length(windowSize)
        )
        self.samplesRealpCopyLock.signal()

        self.samplesImagpCopyLock.wait()
        vDSP_vmul(
            samples.imagp,
            1,
            hammingWindow,
            1,
            &self.samplesImagpCopy,
            1,
            vDSP_Length(windowSize)
        )
        self.samplesImagpCopyLock.signal()
        
        
        //TODO: Perform the FFT
        
        var splitComplex: DSPSplitComplex!
        self.samplesRealpCopyLock.wait()
        self.samplesImagpCopyLock.wait()
        self.samplesRealpCopy.withUnsafeMutableBufferPointer { realPtr in
            self.samplesImagpCopy.withUnsafeMutableBufferPointer { imagPtr in
                splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
            }
        }
        self.samplesImagpCopyLock.signal()
        self.samplesRealpCopyLock.signal()
        
        return splitComplex
    }
    
    deinit {
        self.fftConfigLock.wait()
        vDSP_destroy_fftsetup(self.fftConfig)
        self.fftConfigLock.signal()
    }
}

/*
 {
     guard let FFTUtils = self.FFTUtils else { return }
     
     guard let fft = FFTUtils.fft else {
         print("performFFT(samplesInThisWindow: inout [Float]): FFT setup is nil.")
         return
     }
     
     vDSP.multiply(samplesInThisWindow,
                   FFTUtils.windowingFunction,
                   result: &samplesInThisWindow)
     
     FFTUtils.tempRealParts.withUnsafeMutableBufferPointer { realPtr in
         FFTUtils.tempImaginaryParts.withUnsafeMutableBufferPointer { imagPtr in
             var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!,
                                                imagp: imagPtr.baseAddress!)
             
             samplesInThisWindow.withUnsafeBytes {
                 vDSP_ctoz($0.bindMemory(to: DSPComplex.self).baseAddress!, 2,
                           &splitComplex, 1,
                           vDSP_Length(FFTUtils.windowSize / 2))
             }
         }
     }
     
     FFTUtils.tempRealParts.withUnsafeMutableBufferPointer { realPtr in
         FFTUtils.tempImaginaryParts.withUnsafeMutableBufferPointer { imagPtr in
             FFTUtils.fftRealBuffer.withUnsafeMutableBufferPointer { realBufferPtr in
                 FFTUtils.fftImagBuffer.withUnsafeMutableBufferPointer { imagBufferPtr in
                     var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!,
                                                        imagp: imagPtr.baseAddress!)
                     
                     var bufferSplitComplex = DSPSplitComplex(realp: realBufferPtr.baseAddress!,
                                                              imagp: imagBufferPtr.baseAddress!)
                     
                     let log2n = vDSP_Length(log2(Float(FFTUtils.windowSize)))
                     
                     vDSP_fft_zript(fft,
                                    &splitComplex, 1,
                                    &bufferSplitComplex,
                                    log2n,
                                    FFTDirection(kFFTDirection_Forward))
                 }
             }
         }
     }
     
     FFTUtils.tempRealParts.withUnsafeMutableBufferPointer { realPtr in
         FFTUtils.tempImaginaryParts.withUnsafeMutableBufferPointer { imagPtr in
             var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!,
                                                imagp: imagPtr.baseAddress!)
             
             FFTUtils.frequencyDomainBuffer.withUnsafeMutableBytes { ptr in
                 vDSP_ztoc(&splitComplex, 1,
                           ptr.bindMemory(to: DSPComplex.self).baseAddress!, 2,
                           vDSP_Length(FFTUtils.windowSize / 2))
             }
         }
     }
     
     vDSP.absolute(FFTUtils.frequencyDomainBuffer, result: &FFTUtils.frequencyDomainBuffer)
 }
 */
