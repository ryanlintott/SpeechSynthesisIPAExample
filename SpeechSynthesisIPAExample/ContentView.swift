//
//  ContentView.swift
//  SpeechSynthesisIPAExample
//
//  Created by Ryan Lintott on 2026-06-24.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var ipaText = "blɛnd"
    @State private var voices = Self.availableVoices
    @State private var selectedVoiceIdentifier = Self.defaultVoiceIdentifier

    var body: some View {
        NavigationStack {
            Form {
                Picker("Voice", selection: $selectedVoiceIdentifier) {
                    ForEach(voices, id: \.identifier) { voice in
                        Text("\(voice.name) (\(voice.language))")
                            .tag(voice.identifier)
                    }
                }

                TextField("IPA", text: $ipaText, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .lineLimit(2...4)

                Button("Play", systemImage: "play.fill", action: speakIPA)
                    .disabled(ipaText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .navigationTitle("IPA Speech")
            .onChange(of: selectedVoiceIdentifier) { _, newIdentifier in
                synthesizer.stopSpeaking(at: .immediate)
                synthesizer = AVSpeechSynthesizer()
            }
            .task {
                AVAudioSession.sharedInstance().setSpeechSession()
            }
        }
    }

    private func speakIPA() {
        let ipa = ipaText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard ipa.isEmpty == false else { return }

        let attributedSpeech = NSMutableAttributedString(string: ipa)
        let range = NSRange(location: 0, length: attributedSpeech.length)
        let ipaKey = NSAttributedString.Key(rawValue: AVSpeechSynthesisIPANotationAttribute)
        attributedSpeech.setAttributes([ipaKey: ipa], range: range)

        let utterance = AVSpeechUtterance(attributedString: attributedSpeech)
        utterance.voice = AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier)

        synthesizer.pauseSpeaking(at: .immediate)
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }

    private static var availableVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices().sorted {
            if $0.language == $1.language {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            } else {
                $0.language.localizedStandardCompare($1.language) == .orderedAscending
            }
        }
    }

    private static var defaultVoiceIdentifier: String {
        let voices = availableVoices
        let currentLanguage = AVSpeechSynthesisVoice.currentLanguageCode()

        return nickyVoice(in: voices)?.identifier
            ?? voices.first { $0.language == currentLanguage }?.identifier
            ?? voices.first?.identifier
            ?? ""
    }

    private static func nickyVoice(in voices: [AVSpeechSynthesisVoice]) -> AVSpeechSynthesisVoice? {
        voices.first { $0.identifier.lowercased().contains("nicky") }
    }
}

public extension AVAudioSession {
    /// Sets audioSession to play on mute, pause other spoken audio and duck anything else.
    func setSpeechSession() {
        do {
            try self.setCategory(.playback, options: [.interruptSpokenAudioAndMixWithOthers, .duckOthers])
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
}
