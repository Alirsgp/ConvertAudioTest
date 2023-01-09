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
    var body: some View {
        VStack {
            Button(action: {
                // Convert
                let fileManager = FileManager.default
                do {
                    if let testInputAudioURL = Bundle.main.url(forResource: "input", withExtension: "wav") {
                        let asset = try AVAudioFile(forReading: testInputAudioURL)
                        print("Sample rate for input audio is \(asset.processingFormat.sampleRate)")
                    }
                    copyPCMBuffer(from: Bundle.main.url(forResource: "input", withExtension: "wav")!,
                                  to: try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                                                          .appending(path: "output.wav"))
                    let outputURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                        .appending(path: "output.wav")
                    let asset = try AVAudioFile(forReading: outputURL)
                    print("Sample rate for output audio is \(asset.processingFormat.sampleRate)")
                    
                } catch let error {
                    print("Error is \(error.localizedDescription)")
                }
            }) {
                Text("Convert")
            }
        }
        .padding()
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
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVNumberOfChannelsKey: 1,
        AVSampleRateKey: 16000,
        AVLinearPCMBitDepthKey: buffer.format.settings[AVLinearPCMBitDepthKey] ?? 16
    ]

    do {
        let output = try AVAudioFile(forWriting: url, settings: settings, commonFormat: .pcmFormatInt16, interleaved: false)
        try output.write(from: buffer)

        print("MADE IT")
    } catch {
        print("ERROR IS \(error.localizedDescription)")
        throw error
    }
}

func copyPCMBuffer(from inputUrl: URL, to outputUrl: URL) {
    guard let inputBuffer = readPCMBuffer(url: inputUrl) else {
        fatalError("failed to read \(inputUrl)")
    }
    guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: inputBuffer.format, frameCapacity: inputBuffer.frameLength) else {
        fatalError("failed to create a buffer for writing")
    }
    guard let inputInt16ChannelData = inputBuffer.int16ChannelData else {
        fatalError("failed to obtain underlying input buffer")
    }
    guard let outputInt16ChannelData = outputBuffer.int16ChannelData else {
        fatalError("failed to obtain underlying output buffer")
    }
    print("hiii")
    for channel in 0 ..< Int(inputBuffer.format.channelCount) {
        let p1: UnsafeMutablePointer<Int16> = inputInt16ChannelData[channel]
        let p2: UnsafeMutablePointer<Int16> = outputInt16ChannelData[channel]

        for i in 0 ..< Int(inputBuffer.frameLength) {
            p2[i] = p1[i]
        }
    }

    outputBuffer.frameLength = inputBuffer.frameLength
    print("OVA HERE")
    do {
        try writePCMBuffer(url: outputUrl, buffer: outputBuffer)
        print("Done writing!")
    } catch let error {
        debugPrint("Error is \(error.localizedDescription)")
        fatalError("failed to write \(outputUrl)")
    }
}


