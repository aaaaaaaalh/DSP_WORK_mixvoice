# DSP_WORK_mixvoice

MATLAB 房间混响模拟项目，基于实测的厕所与长走廊房间脉冲响应（RIR）。

## 功能

- 导入 WAV / MP3 / M4A / FLAC 音频
- 选择厕所或长走廊空间
- 0%–100% Dry/Wet 混响强度滑块
- 自动匹配 RIR 与输入音频的采样率
- 显示原声与处理后波形
- 播放原声和处理结果
- 导出 WAV

## 环境

- MATLAB R2025b
- Audio Toolbox
- DSP System Toolbox
- Signal Processing Toolbox

## 使用

将以下文件放到同一个 MATLAB Current Folder：

```text
RoomReverbApp.m
toilet_rir.wav
corridor_rir.wav
```

然后运行：

```matlab
RoomReverbApp
```

如果没有两个 RIR WAV，也可以将 `tolite.m4a` 和 `zoulang.m4a` 放在同一目录，程序会按实验中确定的拍掌时间区间自动截取近似 RIR。

## 算法

房间近似为 LTI 系统：

```text
y[n] = x[n] * h[n]
```

GUI 的混响强度使用 Dry/Wet 混合：

```text
output = (1-a) * dry + a * wet
```

其中 `a` 为 0 到 1。

## 实验结果

T20 外推的 RT60 估算结果：

- 厕所：约 1.048 s
- 长走廊：约 1.401 s

主观听感中，厕所反射更密集，长走廊更空旷、衰减更慢。

## 说明

RIR 来自手机拍掌测量，因此属于近似房间脉冲响应，不是专业测量级 RIR。
