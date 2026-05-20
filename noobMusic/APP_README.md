# noobGuitar

SwiftUI 原生 iOS 吉他练习 App，当前版本已经从单一练习页整理成多入口结构，围绕练习台、轻打卡、六线谱谱本、Guidebook 和练习记录展开。

## 当前功能

- Home Hub：首页按功能分类进入练习台、轻打卡、谱本、Guidebook、练习记录。
- 练习台：交互指板、和弦库、节拍器、麦克风监听、和弦进行、Capo、扫弦练习入口。
- 轻打卡练习：按和弦类型生成卡片式练习流程，支持 BPM 调节、手动 Pass、上一张/跳过。
- 谱本：可按六线谱方式编辑每根弦内容，写右手标记，插入顺扫/分解/制音模板，并整谱预览。
- Guidebook：包含六线谱阅读、基础乐理、右手记号、初学路线和示例谱。
- 练习记录：按天累计练习时长，展示连续天数、月统计和热力图。
- 主题系统：统一暖色浅色视觉风格，支持主题色切换。

## 本次版本更新

- 新增 `HomeHubView` 作为主入口，首页功能分组更清晰。
- 新增 `DailyChordChallengeView`，提供更轻量的打卡练习流。
- 新增 `TabComposerView`，支持六线谱式谱本编辑和模板填充。
- 新增 `GuidebookView`，补充读谱、乐理和练习路线内容。
- 新增 `SurfaceStyle.swift`，统一卡片、背景、返回按钮等视觉样式。
- 练习台、扫弦练习、练习记录等页面已统一为浅色简洁 UI。
- 修复 Capo 对主页扫弦和麦克风识别结果的影响。
- 修复练习计时在页面切换时中断的问题，改为基于 `scenePhase` 跟踪。
- iOS 部署目标统一到 `iOS 17.0`，并兼容 iPhone / iPad。
- 项目已配置麦克风权限文案。

## 主要文件

- `noobMusic/noobMusicApp.swift`：App 入口。
- `noobMusic/HomeHubView.swift`：首页功能分发。
- `noobMusic/ContentView.swift`：练习台主界面。
- `noobMusic/DailyChordChallengeView.swift`：轻打卡练习。
- `noobMusic/TabComposerView.swift`：六线谱谱本编辑。
- `noobMusic/GuidebookView.swift`：教学手册。
- `noobMusic/PracticeLogView.swift`：练习记录视图。
- `noobMusic/SurfaceStyle.swift`：共享视觉样式。

## 技术信息

- UI：SwiftUI
- 音频：AVAudioEngine + AVAudioSourceNode
- 麦克风分析：AVFoundation + Accelerate / vDSP FFT
- 持久化：UserDefaults
- 最低系统：iOS 17.0

## 已确认项

- `xcodebuild -project noobMusic.xcodeproj -scheme noobMusic -destination generic/platform=iOS CODE_SIGNING_ALLOWED=NO build` 已通过。
- `NSMicrophoneUsageDescription` 已写入工程配置。

## 仍可继续优化的点

- 谱本目前是本地临时编辑态，尚未做保存/导出。
- 轻打卡当前以手动 Pass 为主，后续可再叠加更稳健的识别辅助。
- iPad 大屏布局仍可针对 regular size class 单独细化。
