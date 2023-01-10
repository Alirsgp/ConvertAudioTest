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
    print("Attempting to use converter now")
    do {
        converter.reset()
        print("Reset converter")
        converter.bitRate = Int(outputFormat.sampleRate) * Int(outputFormat.streamDescription.pointee.mBitsPerChannel)
        print("Changed converter bit rate")
        
        // Create the output file and prepare it for writing
        let tempOutputURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(path: "tempOutputURL.wav")
        let outputFile = try AVAudioFile(forWriting: tempOutputURL, settings: outputFormat.settings)
        print("Created outputFile to write to")
        
        // Perform the conversion
        print("output buffer frame capacity is \(outputBuffer.frameCapacity)")
        print("input buffer frame capacity is \(inputBuffer.frameLength)")
        try converter.convert(to: outputBuffer, from: inputBuffer)
        print("Got past convert")
        try outputFile.write(from: outputBuffer)
        print("Got past writing out output file")
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


