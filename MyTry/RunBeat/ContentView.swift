import SwiftUI

struct ContentView: View {
    @StateObject private var metronome = MetronomeEngine()

    private let presets = [150, 160, 170, 180]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.07, blue: 0.13), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    header
                    cadenceCard
                    controlsCard
                    safetyNote
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
        .preferredColorScheme(.dark)
        .alert(
            "音频提示",
            isPresented: Binding(
                get: { metronome.lastError != nil },
                set: { presented in
                    if !presented { metronome.clearError() }
                }
            )
        ) {
            Button("知道了", role: .cancel) {
                metronome.clearError()
            }
        } message: {
            Text(metronome.lastError ?? "未知错误")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("RUNBEAT")
                    .font(.caption.weight(.bold))
                    .tracking(3)
                    .foregroundStyle(.green)

                Text("让音乐跟着你的脚步")
                    .font(.title2.bold())
            }

            Spacer()

            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)
                .accessibilityHidden(true)
        }
    }

    private var cadenceCard: some View {
        VStack(spacing: 24) {
            VStack(spacing: 0) {
                Text("\(metronome.bpm)")
                    .font(.system(size: 84, weight: .black, design: .rounded))
                    .monospacedDigit()

                Text("步 / 分钟")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 26) {
                roundButton(systemName: "minus", label: "降低步频") {
                    metronome.setBPM(metronome.bpm - 1)
                }

                Button {
                    metronome.toggle()
                } label: {
                    Image(systemName: metronome.isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 28, weight: .bold))
                        .frame(width: 86, height: 86)
                        .foregroundStyle(.black)
                        .background(metronome.isPlaying ? Color.orange : Color.green)
                        .clipShape(Circle())
                        .shadow(
                            color: (metronome.isPlaying ? Color.orange : Color.green).opacity(0.35),
                            radius: 18
                        )
                }
                .accessibilityLabel(metronome.isPlaying ? "停止节拍" : "开始节拍")

                roundButton(systemName: "plus", label: "提高步频") {
                    metronome.setBPM(metronome.bpm + 1)
                }
            }

            Slider(
                value: Binding(
                    get: { Double(metronome.bpm) },
                    set: { metronome.setBPM(Int($0.rounded())) }
                ),
                in: 80...220,
                step: 1
            )
            .tint(.green)
            .accessibilityLabel("步频")
            .accessibilityValue("每分钟 \(metronome.bpm) 步")

            HStack(spacing: 10) {
                ForEach(presets, id: \.self) { value in
                    Button("\(value)") {
                        metronome.setBPM(value)
                    }
                    .buttonStyle(PresetButtonStyle(selected: metronome.bpm == value))
                    .accessibilityLabel("设置为每分钟 \(value) 步")
                }
            }
        }
        .padding(24)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.08))
        }
    }

    private var controlsCard: some View {
        VStack(spacing: 22) {
            HStack {
                Label("节拍音量", systemImage: "speaker.wave.2.fill")
                    .font(.headline)

                Spacer()

                Text("\(Int(metronome.volume * 100))%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            Slider(
                value: Binding(
                    get: { Double(metronome.volume) },
                    set: { metronome.setVolume(Float($0)) }
                ),
                in: 0...1
            )
            .tint(.green)
            .accessibilityLabel("节拍音量")

            Divider()

            Toggle(
                isOn: Binding(
                    get: { metronome.accentEnabled },
                    set: { metronome.setAccentEnabled($0) }
                )
            ) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("四拍强音")
                        .font(.headline)
                    Text("每四拍突出第一拍，帮助保持节奏")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.green)
        }
        .padding(22)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var safetyNote: some View {
        Label(
            "可以先播放你喜欢的音乐，再启动节拍。拔掉耳机或断开蓝牙时，节拍会自动停止。",
            systemImage: "headphones"
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func roundButton(
        systemName: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .bold))
                .frame(width: 58, height: 58)
                .foregroundStyle(.primary)
                .background(.white.opacity(0.1))
                .clipShape(Circle())
        }
        .accessibilityLabel(label)
    }
}

private struct PresetButtonStyle: ButtonStyle {
    let selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(selected ? .black : .primary)
            .background(selected ? Color.green : Color.white.opacity(0.08))
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

#Preview {
    ContentView()
}
