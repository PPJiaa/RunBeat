# RunBeat

RunBeat 是一个轻量的 iPhone 跑步节拍叠加器。它不会读取或播放用户的音乐，而是使用 iOS 音频混音能力，将稳定的步频节拍叠加在 Apple Music、Spotify、QQ 音乐、网易云音乐等应用的声音之上。

## 已实现

- 80–220 BPM 步频调节
- 150、160、170、180 BPM 快捷预设
- 独立节拍音量
- 可关闭的四拍强音
- 锁屏及切换应用后继续播放
- 使用 PCM 音频缓冲区循环，避免后台 Timer 抖动和累计漂移
- 电话、Siri 等系统中断结束后自动恢复
- 耳机或蓝牙设备断开时自动停止，避免突然外放
- 不注册 Now Playing 信息，尽量保留音乐 App 的锁屏控制权

## 在 Mac 上运行

1. 使用 Xcode 打开 `RunBeat.xcodeproj`。
2. 选中 RunBeat target，在 **Signing & Capabilities** 中选择你的 Team。
3. 如 Bundle Identifier 与已有应用冲突，将 `com.example.RunBeat` 改为自己的唯一标识，例如 `com.yourname.RunBeat`。
4. 连接 iPhone，并在设备上信任这台 Mac。
5. 在 Xcode 顶部选择你的 iPhone，然后点击 Run。
6. 先在任意音乐 App 播放音乐，再回到 RunBeat 点击绿色播放按钮。
7. 锁屏并持续运行，确认音乐和节拍同时从耳机输出。

## 只有 Windows

项目包含 GitHub Actions 云端 macOS 构建流程，可以生成供 AltStore 临时签名的 IPA。完整步骤参见 [`WINDOWS_INSTALL.md`](WINDOWS_INSTALL.md)。

项目已经在 `Info.plist` 中声明 `UIBackgroundModes = audio`，音频会话使用 `.playback + .mixWithOthers`。不需要麦克风、媒体资料库或网络权限。

## 建议的真机测试

- Apple Music、Spotify、QQ 音乐、网易云音乐分别测试
- 有线耳机、AirPods 和普通蓝牙耳机分别测试
- 锁屏运行至少 30 分钟，确认节拍没有漂移
- 测试来电、Siri、闹钟中断后的恢复
- 播放时断开耳机，确认节拍立即停止
- 切换歌曲、暂停和恢复音乐，确认 RunBeat 不抢占音乐

## 当前限制

- 调整 BPM 时会从新的四拍小节起点重新开始，这是第一版的预期行为。
- 尚未包含正式 App Store 图标。
- 当前工作区是 Windows 环境，无法运行 Apple 的 iOS SDK；最终编译、签名和真机验证必须在 Mac 的 Xcode 中完成。
