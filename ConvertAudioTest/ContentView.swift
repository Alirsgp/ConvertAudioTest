//
//  ContentView.swift
//  convertAudio
//
//  Created by Ali Mohammadian on 1/8/23.
//

import SwiftUI
import AVFoundation
import Foundation

// Using AVAudioConverter to covert from one file format to another.
func convertAudioFormat(sourceName: String, sourceExtension: String, destinationName: String, destinationExtension: String) {
    // 1. Open the audio file to process and get its processing format.
    let sourceFileURL = Bundle.main.url(forResource: sourceName, withExtension: sourceExtension)!
    let sourceFile = try! AVAudioFile(forReading: sourceFileURL)
    let sourceFormat = sourceFile.processingFormat
    
    // 2. Change this to be your preferred output format.
    let destinationFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: true)!
    
    // 3. Create an output file and an output buffer.
    let downloads = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let destinationURL = URL(fileURLWithPath: downloads + "/" + destinationName + "." + destinationExtension)
    
    var destinationFile = try? AVAudioFile(forWriting: destinationURL,
                                           settings: destinationFormat.settings,
                                           commonFormat: destinationFormat.commonFormat,
                                           interleaved: destinationFormat.isInterleaved)
    
    // 4. Create an audio buffer for incoming and outgoing audio data.
    let kFrameCapacity: AVAudioFrameCount = 4096
    let sourceBuffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: kFrameCapacity)
    let destinationBuffer = AVAudioPCMBuffer(pcmFormat: destinationFormat, frameCapacity: kFrameCapacity)
    
    // 5. Create an instance of AVAudioConverter to handle the actual conversion. Provide the source and destination format.
    let converter = AVAudioConverter(from: sourceFormat, to: destinationFormat)
    let startTime = NSDate()
    var done = false
    print("Beginning conversion")
    
    // 6. Loop over convert function until there is no more source data left. When the convertor has data (.haveData) write this to the output file.
    while !done {
        let errorPtr: NSErrorPointer = nil
        let conversionStatus = converter!.convert(to: destinationBuffer!, error: errorPtr, withInputFrom: { (packetCount, inputStatus) -> AVAudioBuffer? in
            
            var fileError = false
            do {
                try sourceFile.read(into: sourceBuffer!, frameCount: packetCount)
            } catch {
                fileError = true
            }
            
            if !fileError && sourceBuffer!.frameLength > 0 {
                inputStatus.pointee = .haveData
                return sourceBuffer
            }
            
            inputStatus.pointee = .endOfStream
            return nil
        })
        
        switch conversionStatus {
        case .inputRanDry:
            fallthrough
        case .haveData:
            if destinationBuffer!.frameLength > 0 {
                do {
                    try destinationFile?.write(from: destinationBuffer!)
                } catch {
                    print("Error writing destination file: \(error)")
                    done = true
                }
            }
        case .error:
            fallthrough
        case .endOfStream:
            done = true
        @unknown default:
            fatalError()
        }
    }
    
    let elapsed = abs(startTime.timeIntervalSinceNow)
    print("Conversion completed in " + String(format: "%.02f", elapsed) + " Seconds")
    
    // 7. nil destination file to force close
    destinationFile = nil
    
    // 8. Compare the duration of the source and destination file. If the conversion has been successful, the source and destination file should roughly the same length
    let sourceDuration = Double(sourceFile.length) / sourceFile.fileFormat.sampleRate
    do {
        // We get an exception saying resource not available
        _ = try destinationURL.checkResourceIsReachable()
        // We get an exception here if we try to read the destinationURL as the file does not exist
        let destinationReadFile = try AVAudioFile(forReading: destinationURL)
        let destinationDuration = Double(destinationReadFile.length) / destinationReadFile.fileFormat.sampleRate
        if Int(sourceDuration) == Int(destinationDuration) {
            print("Successfully converted")
            print("Source file : \(sourceFileURL)")
            print("Source format : \(sourceFormat)")
            print("")
            print("To")
            print("")
            print("Destination file : \(destinationURL)")
            print("Destination format : \(destinationFormat)")
        } else {
            print("File conversion failed")
        }
    } catch let exception {
        print("Exception is on step 8: \(exception.localizedDescription)")
    }

    

}

struct ContentView: View {
    
    var body: some View {
        Button("Convert") {
            convertAudioFormat(sourceName: "smallTest", sourceExtension: "m4a", destinationName: "appleOutput", destinationExtension: "wav")
        }
    }
}
