//
//  ContentView.swift
//  convertAudio
//
//  Created by Ali Mohammadian on 1/8/23.
//

import SwiftUI
import AVFoundation
import Foundation

struct ContentView: View {
    private var sampleUrl: URL? {
        Bundle.main.url(forResource: "smallTest", withExtension: "m4a")
    }
    
    private var desiredOutputAudioFormatURL: URL? {
        Bundle.main.url(forResource: "desiredOutputFormat", withExtension: "wav")
    }
    
    var body: some View {
        VStack {
            Button(action: {
                // The URL where you want to save the converted audio file
                guard let inputToChange = sampleUrl else {
                    print("Couldn't get input file to change")
                    return
                }
                
                guard let outputFile = desiredOutputAudioFormatURL else {
                    print("Couldn't get output file")
                    return
                }
                
                convertAudio(inputURL: inputToChange, outputURL: outputFile)
                
            }) {
                Text("Convert")
            }
        }
        .padding()
    }
}

func convertAudio(inputURL: URL, outputURL: URL) {
    
    guard let inputBuffer = readPCMBuffer(url: inputURL) else {
        print("Couldn't get input buffer")
        return
    }
    
    // The desired output format for the audio file
    guard let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                           sampleRate: 16000,
                                           channels: 1,
                                           interleaved: false) else {
        print("Couldn't get outputFormat")
        return
    }
    
    guard let outputBuffer = readPCMBuffer(url: outputURL) else {
        print("Couldn't get output buffer")
        return
    }
    
    // Create an AVAudioConverter
    guard let converter = AVAudioConverter(from: inputBuffer.format, to: outputFormat) else {
        print("Couldn't create converter")
        return
    }
    
    // Open the input file and prepare it for conversion
    do {
        converter.reset()
        converter.bitRate = Int(outputFormat.sampleRate) * Int(outputFormat.streamDescription.pointee.mBitsPerChannel)
        
        // Create the output file and prepare it for writing
        let outputFile = try AVAudioFile(forWriting: outputURL, settings: outputFormat.settings)
        
        // Perform the conversion
        try converter.convert(to: outputBuffer, from: inputBuffer)
        try outputFile.write(from: outputBuffer)
    } catch let error {
        print("error thrown is \(error.localizedDescription)")
    }
    
}


func readPCMBuffer(url: URL) -> AVAudioPCMBuffer? {
    guard let input = try? AVAudioFile(forReading: url, commonFormat: .pcmFormatInt16, interleaved: false) else {
        return nil
    }
    guard let buffer = AVAudioPCMBuffer(pcmFormat: input.processingFormat, frameCapacity: AVAudioFrameCount(input.length)) else {
        return nil
    }
    do {
        try input.read(into: buffer)
    } catch {
        return nil
    }
    return buffer
}

func writePCMBuffer(url: URL, buffer: AVAudioPCMBuffer) throws {
    let settings: [String: Any] = [
        AVFormatIDKey: buffer.format.settings[AVFormatIDKey] ?? kAudioFormatLinearPCM,
        AVNumberOfChannelsKey: buffer.format.settings[AVNumberOfChannelsKey] ?? 2,
        AVSampleRateKey: buffer.format.settings[AVSampleRateKey] ?? 44100,
        AVLinearPCMBitDepthKey: buffer.format.settings[AVLinearPCMBitDepthKey] ?? 16
    ]
    
    do {
        let output = try AVAudioFile(forWriting: url, settings: settings, commonFormat: .pcmFormatInt16, interleaved: false)
        try output.write(from: buffer)
    } catch {
        print("ERROR IS \(error.localizedDescription)")
        throw error
    }
}


