# 只有 Windows 时安装 RunBeat

这条路线分为两部分：GitHub Actions 使用云端 Mac 编译 `RunBeat-unsigned.ipa`，AltStore 在 Windows 上使用你的 Apple 账号为 IPA 临时签名并安装到自己的 iPhone。

## 第一部分：生成 IPA

1. 注册或登录 [GitHub](https://github.com/)。
2. 创建一个名为 `RunBeat` 的仓库。公开仓库的标准 GitHub Actions runner 免费；私人仓库会使用账号包含的 Actions 额度。
3. 将本项目中的所有内容上传到仓库根目录。上传后应当能直接看到：

   ```text
   .github/workflows/build-ios.yml
   RunBeat.xcodeproj/
   RunBeat/
   README.md
   ```

4. 打开仓库的 **Actions** 页面。
5. 在左侧选择 **Build RunBeat IPA**。
6. 点击 **Run workflow**，再次确认运行。
7. 等待任务变成绿色。第一次运行通常需要几分钟。
8. 打开该次运行记录，在页面底部的 **Artifacts** 下载 `RunBeat-unsigned-ipa`。
9. 解压下载的 ZIP，得到 `RunBeat-unsigned.ipa`。

如果构建失败，请打开失败步骤并复制完整错误信息，不要只截取最后一行。

## 第二部分：在 Windows 安装 AltStore

以下步骤依据 AltStore 官方 Windows 指南：

1. 从 Apple 官网安装桌面版 iTunes 和 iCloud。AltStore 官方建议不要使用 Microsoft Store 版本。
2. 下载并安装 [AltServer for Windows](https://cdn.altstore.io/file/altstore/altinstaller.zip)。
3. 以管理员身份运行 AltServer，并允许其访问专用网络。
4. 使用数据线连接并解锁 iPhone，在手机上选择“信任此电脑”。
5. 打开 iTunes，登录 Apple 账号，并为该 iPhone 开启“通过 Wi-Fi 与此 iPhone 同步”。
6. 点击 Windows 任务栏右下角的 AltServer 图标，选择 **Install AltStore → 你的 iPhone**。
7. 按提示输入 Apple 账号。AltStore 官方说明，账号凭据只发送给 Apple，用于配置临时签名。
8. 在 iPhone 中打开 **设置 → 通用 → VPN 与设备管理**，信任对应的 Apple 账号。
9. iOS 16 或更高版本还要打开 **设置 → 隐私与安全性 → 开发者模式**，并按提示重启。

AltStore 官方完整说明：[Windows 安装指南](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows)

## 第三部分：安装 RunBeat IPA

1. 将 `RunBeat-unsigned.ipa` 保存到 iPhone 的“文件”应用，例如通过 iCloud Drive、网盘或聊天文件传输。
2. 打开 iPhone 上的 AltStore，进入 **My Apps**。
3. 点击左上角的 `+`，从“文件”中选择 `RunBeat-unsigned.ipa`。
4. 等待签名和安装完成，RunBeat 会出现在主屏幕。
5. 如果系统再次询问开发者模式或信任，请按提示确认。

## 每 7 天刷新一次

免费 Apple 账号生成的应用签名有效期为 7 天。让电脑和 iPhone 处于同一 Wi-Fi，Windows 上保持 AltServer 运行，然后在 AltStore 的 **My Apps** 页面点击 **Refresh All**。AltStore 也会尝试在后台自动刷新。

如果超过 7 天没有刷新，RunBeat 暂时无法打开，但重新刷新或安装即可恢复。Apple 免费账号通常最多同时安装三个此类应用。

## 使用 RunBeat

1. 连接耳机或 AirPods。
2. 先在你常用的音乐 App 中播放音乐。
3. 打开 RunBeat，选择 BPM 并点击绿色播放键。
4. 回到音乐 App 或锁屏；音乐和节拍应当同时播放。

不要在跑步时把音量开得过高，并尽量保留对车辆和环境声音的感知。
