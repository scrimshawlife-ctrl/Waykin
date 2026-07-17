#!/usr/bin/env swift

import Foundation

struct Tone {
    let name: String
    let frequency: Double
    let overtone: Double
    let duration: Double
    let amplitude: Double
}

let tones = [
    Tone(name: "companion_near", frequency: 392, overtone: 587, duration: 0.55, amplitude: 0.14),
    Tone(name: "companion_ahead", frequency: 440, overtone: 659, duration: 0.60, amplitude: 0.13),
    Tone(name: "distant_presence", frequency: 110, overtone: 165, duration: 0.85, amplitude: 0.11),
    Tone(name: "pursuit_pressure", frequency: 82, overtone: 123, duration: 0.75, amplitude: 0.15),
    Tone(name: "pursuit_release", frequency: 196, overtone: 294, duration: 0.70, amplitude: 0.11),
    Tone(name: "bond_motif", frequency: 523, overtone: 784, duration: 0.90, amplitude: 0.13),
    Tone(name: "quiet_shift", frequency: 261, overtone: 392, duration: 1.00, amplitude: 0.08)
]

let sampleRate = 22_050
let outputDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("App/Resources/Audio", isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

func appendLittleEndian<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
    var littleEndian = value.littleEndian
    withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
}

for tone in tones {
    let sampleCount = Int(tone.duration * Double(sampleRate))
    var samples = Data(capacity: sampleCount * 2)

    for index in 0..<sampleCount {
        let time = Double(index) / Double(sampleRate)
        let progress = Double(index) / Double(max(1, sampleCount - 1))
        let envelope = pow(sin(.pi * progress), 1.8)
        let fundamental = sin(2 * .pi * tone.frequency * time)
        let overtone = 0.32 * sin(2 * .pi * tone.overtone * time)
        let value = max(-1, min(1, (fundamental + overtone) * tone.amplitude * envelope))
        appendLittleEndian(Int16(value * Double(Int16.max)), to: &samples)
    }

    var wave = Data()
    wave.append(contentsOf: "RIFF".utf8)
    appendLittleEndian(UInt32(36 + samples.count), to: &wave)
    wave.append(contentsOf: "WAVE".utf8)
    wave.append(contentsOf: "fmt ".utf8)
    appendLittleEndian(UInt32(16), to: &wave)
    appendLittleEndian(UInt16(1), to: &wave)
    appendLittleEndian(UInt16(1), to: &wave)
    appendLittleEndian(UInt32(sampleRate), to: &wave)
    appendLittleEndian(UInt32(sampleRate * 2), to: &wave)
    appendLittleEndian(UInt16(2), to: &wave)
    appendLittleEndian(UInt16(16), to: &wave)
    wave.append(contentsOf: "data".utf8)
    appendLittleEndian(UInt32(samples.count), to: &wave)
    wave.append(samples)

    try wave.write(to: outputDirectory.appendingPathComponent("\(tone.name).wav"), options: .atomic)
}

print("Generated \(tones.count) deterministic placeholder WAV files in \(outputDirectory.path)")
