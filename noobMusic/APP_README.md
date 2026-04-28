# 🎸 noobGuitar

一款用 SwiftUI 原生实现的 iOS 吉他练习 App，无任何第三方依赖。

---

## 功能模块

### 🎵 音频引擎 — Karplus-Strong 合成 (`GuitarAudioEngine`)
- 基于 **Karplus-Strong** 算法的物理建模吉他音色，每根弦独立延迟线
- 支持单弦拨弦（pluck）和全弦扫弦（strum），顺扫 / 逆扫带可调时间间隔
- 扫弦速度四档：慢 / 中 / 快 / 极快
- 开放弦标准定弦：E2 A2 D3 G3 B3 E4（MIDI 40–64）
- 延迟线使用 `UnsafeMutablePointer<Float>` 平坦 C 缓冲区，彻底规避 Swift ARC/COW 在音频线程引发的崩溃

### 🎸 交互指板 (`FretboardView`)
- 6 弦 × 5 品可视窗口，支持滑动浏览 1–15 品
- 按下任意格发声 + 橙色高亮点，再次点击取消
- 每格显示音名暗提示（dim），按下后弹出带音名的橙色圆点
- 超出视野的已按品格在边缘显示橙色箭头指示
- 变调夹（Capo）在指板上可视化显示
- **左上角长按圆形按钮**解锁 / 锁定指板横向滑动，锁定时禁止误触滑动
- 弦名标签（左侧）点击直接拨弦

### 🔢 和弦库 (`GuitarModel`)
- 内置 **70+ 和弦**，覆盖大调 / 小调 / 七和弦 / 爵士 / 挂留&其他 五大分类
- 每个和弦附带 mini 指法图（6 格小圆点，含品格数字 + 消音标记）
- **实时和弦识别**：根据当前按弦位置 + Capo 偏移，匹配内置模板库识别和弦名

### 🥁 节拍器 (`MetronomeEngine`)
- BPM 范围 40–220，Slider 实时调节
- 每拍闪光动画 + 可配合和弦进行联动

### 🎼 和弦进行 (`ProgressionEngine`)
- 8 槽位循环播放，可从和弦库点击分配和弦
- 每个槽位支持 1 / 2 / 4 拍时长切换
- Loop 模式开关，非 Loop 模式播完自动停止
- 播放时高亮当前槽位并跟随节拍器 BPM

### 🎤 麦克风监听 (`MicListenerEngine`)
- 使用 AVFoundation + vDSP FFT（4096 点 Hanning 窗）实时分析麦克风音频
- 识别主频对应音名，与目标和弦比对输出 0–100% 匹配度
- 圆形进度条 + 颜色反馈（完美 / 接近 / 加油 / 等待）

### 🎯 扫弦练习 (`StrumPracticeView`)
- 全屏练习模式，纯 SwiftUI Bézier 曲线绘制的吉他摆锤动画，跟随节拍器节拍左右摆动
- 支持**单和弦**和**和弦进行**两种练习模式
- 每次摆锤触底自动扫弦发声（顺扫 / 逆扫交替）
- 节拍点阵 + BPM 控制，竖屏 / 横屏自适应布局

### 📅 练习打卡 (`PracticeLogEngine` + `PracticeLogView`)
- App 打开自动开始计时，退出时自动保存当天练习时长
- 按天累计，持久化到 UserDefaults
- **GitHub 热力图**风格月历：练习越久颜色越深（0 / <5分 / 5-15分 / 15-30分 / 30分+ 共五档）
- 今日进度卡片：圆环 + 30 分钟目标进度条，实时跳动
- 统计面板：🔥 连续打卡天数 / 本月总时长 / 最佳单日
- 点击任意日期查看当天详情，左右箭头翻月

### 🎨 主题系统 (`ThemeEngine`)
- 5 套内置主题：🎸 原木橙 / 💻 极客蓝 / 🌌 霓虹紫 / 🌿 清新绿 / 🌸 玫瑰红
- 主题色驱动全局 accent / glow / boardTint，选择后持久化到 UserDefaults

### 📐 自适应布局
- **竖屏**：VStack 布局，指板高度动态适配屏幕高度
- **横屏**：左右分栏，左列指板（54%宽）+ 右列可滚动面板（46%宽），和弦库移入右列
- 中间三个面板（扫弦 / 信息 / Capo）支持**长按拖动换位**，顺序持久化到 UserDefaults

---

## 文件结构

```
noobMusic/
├── noobMusicApp.swift        # App 入口
├── ContentView.swift         # 主界面，布局 & 所有子面板
├── FretboardView.swift       # 交互指板
├── GuitarModel.swift         # 数据模型：和弦库、和弦识别、ViewModel
├── GuitarAudioEngine.swift   # Karplus-Strong 音频合成（UnsafeMutablePointer 平坦缓冲区）
├── MetronomeEngine.swift     # 节拍器
├── ProgressionEngine.swift   # 和弦进行
├── MicListenerEngine.swift   # 麦克风监听 & FFT
├── StrumPracticeView.swift   # 扫弦练习（吉他摆锤动画）
├── PracticeLogEngine.swift   # 练习打卡数据引擎
├── PracticeLogView.swift     # 练习打卡热力日历界面
└── ThemeEngine.swift         # 主题系统
```

---

## 技术栈

| 层级 | 技术 |
|------|------|
| UI | SwiftUI（纯原生，无 UIKit 混排） |
| 音频 | AVAudioEngine + AVAudioSourceNode |
| 信号处理 | vDSP / Accelerate（FFT） |
| 状态管理 | ObservableObject + @Published |
| 持久化 | UserDefaults（主题、面板顺序、练习日志） |
| 最低系统 | iOS 17+ |

---

## 已知 & 待办

- [ ] 音频在后台会被系统静音（未配置 Background Audio capability）
- [ ] 麦克风需要 Info.plist 添加 `NSMicrophoneUsageDescription`
- [ ] 和弦识别偶有歧义（同音异名和弦），可引入低音根音权重优化
- [ ] 横屏下 iPad 布局未单独适配 regular size class
- [ ] 练习打卡支持手动补录历史日期
