import AVFoundation
import Combine
import Foundation

/// A sample-accurate metronome that mixes with audio from other apps.
final class MetronomeEngine: ObservableObject {
    @Published private(set) var bpm: Int = 170
    @Published private(set) var volume: Float = 0.45
    @Published private(set) var isPlaying = false
    @Published private(set) var accentEnabled = true
    @Published private(set) var lastError: String?

    private let audioEngine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate = 44_100.0
    private let beatsPerBar = 4
    private var shouldResumeAfterInterruption = false
    private var notificationTokens: [NSObjectProtocol] = []

    init() {
        configureAudioSessionCategory()
        configureAudioEngine()
        observeAudioEvents()
    }

    deinit {
        notificationTokens.forEach(NotificationCenter.default.removeObserver)
    }

    func toggle() {
        isPlaying ? stop() : start()
    }

    func start() {
        guard !isPlaying else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(true)

            if !audioEngine.isRunning {
                audioEngine.prepare()
                try audioEngine.start()
            }

            schedulePattern()
            player.play()
            isPlaying = true
            lastError = nil
        } catch {
            isPlaying = false
            lastError = "无法启动节拍：\(error.localizedDescription)"
        }
    }

    func stop() {
        stop(deactivateSession: true)
    }

    func setBPM(_ value: Int) {
        let newBPM = min(max(value, 80), 220)
        guard newBPM != bpm else { return }
        bpm = newBPM
        rescheduleIfPlaying()
    }

    func setVolume(_ value: Float) {
        let newVolume = min(max(value, 0), 1)
        volume = newVolume
        player.volume = newVolume
    }

    func setAccentEnabled(_ enabled: Bool) {
        guard enabled != accentEnabled else { return }
        accentEnabled = enabled
        rescheduleIfPlaying()
    }

    func clearError() {
        lastError = nil
    }

    private func configureAudioSessionCategory() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
        } catch {
            lastError = "音频配置失败：\(error.localizedDescription)"
        }
    }

    private func configureAudioEngine() {
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 2
        ) else {
            lastError = "无法创建音频格式"
            return
        }

        audioEngine.attach(player)
        audioEngine.connect(player, to: audioEngine.mainMixerNode, format: format)
        player.volume = volume
    }

    private func rescheduleIfPlaying() {
        guard isPlaying else { return }
        player.stop()
        schedulePattern()
        player.play()
    }

    private func schedulePattern() {
        guard let buffer = makePatternBuffer() else {
            lastError = "无法生成节拍声音"
            return
        }

        player.scheduleBuffer(buffer, at: nil, options: [.loops])
    }

    /// Generates a complete four-beat bar. Looping the PCM buffer avoids
    /// background Timer jitter and keeps the cadence sample-accurate.
    private func makePatternBuffer() -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 2
        ) else {
            return nil
        }

        let framesPerBeat = Int(round(sampleRate * 60.0 / Double(bpm)))
        let totalFrames = framesPerBeat * beatsPerBar

        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(totalFrames)
        ), let channels = buffer.floatChannelData else {
            return nil
        }

        buffer.frameLength = AVAudioFrameCount(totalFrames)
        let channelCount = Int(format.channelCount)

        for channel in 0..<channelCount {
            channels[channel].initialize(repeating: 0, count: totalFrames)
        }

        for beat in 0..<beatsPerBar {
            let accentedBeat = accentEnabled && beat == 0
            let frequency = accentedBeat ? 1_250.0 : 900.0
            let amplitude: Float = accentedBeat ? 0.78 : 0.52
            let startFrame = beat * framesPerBeat
            let clickFrames = min(Int(sampleRate * 0.045), framesPerBeat)

            for index in 0..<clickFrames {
                let time = Double(index) / sampleRate
                let envelope = exp(-75.0 * time)
                let attack = min(1.0, Double(index) / (sampleRate * 0.002))
                let value = amplitude * Float(
                    sin(2.0 * Double.pi * frequency * time) * envelope * attack
                )

                for channel in 0..<channelCount {
                    channels[channel][startFrame + index] = value
                }
            }
        }

        return buffer
    }

    private func stop(deactivateSession: Bool) {
        player.stop()
        audioEngine.stop()
        isPlaying = false

        if deactivateSession {
            do {
                try AVAudioSession.sharedInstance().setActive(
                    false,
                    options: [.notifyOthersOnDeactivation]
                )
            } catch {
                lastError = "停止音频时出现问题：\(error.localizedDescription)"
            }
        }
    }

    private func observeAudioEvents() {
        let center = NotificationCenter.default

        notificationTokens.append(
            center.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: AVAudioSession.sharedInstance(),
                queue: .main
            ) { [weak self] notification in
                self?.handleInterruption(notification)
            }
        )

        notificationTokens.append(
            center.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: AVAudioSession.sharedInstance(),
                queue: .main
            ) { [weak self] notification in
                self?.handleRouteChange(notification)
            }
        )
    }

    private func handleInterruption(_ notification: Notification) {
        guard
            let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: rawType)
        else {
            return
        }

        switch type {
        case .began:
            shouldResumeAfterInterruption = isPlaying
            player.pause()

        case .ended:
            let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)

            guard shouldResumeAfterInterruption, options.contains(.shouldResume) else {
                shouldResumeAfterInterruption = false
                stop(deactivateSession: false)
                return
            }

            shouldResumeAfterInterruption = false
            restartAfterInterruption()

        @unknown default:
            break
        }
    }

    private func restartAfterInterruption() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            if !audioEngine.isRunning {
                try audioEngine.start()
            }
            player.play()
            isPlaying = true
        } catch {
            isPlaying = false
            lastError = "音频中断后无法恢复：\(error.localizedDescription)"
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        guard
            let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason)
        else {
            return
        }

        // Stop when headphones or a Bluetooth route disappears so the beat
        // does not unexpectedly play through the iPhone speaker.
        if reason == .oldDeviceUnavailable, isPlaying {
            stop()
        }
    }
}
