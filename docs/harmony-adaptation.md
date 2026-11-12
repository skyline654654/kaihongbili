# 鸿蒙适配手册

本文只写**已经落到代码里**的东西，以及每条选择的官方依据。所有 API 签名的出处见
[鸿蒙 API 调研记录](research/harmonyos-api-notes.md)（取自 gitee `openharmony/docs` master 原文）。

## 1. 总体结构：ArkUI 原生壳 + Flutter 内容

```
harmony/                         DevEco Studio 打开这个目录
  AppScope/app.json5             bundleName = dev.bilisail.harmony
  entry/src/main/module.json5    metadata: ohos.arkui.UIMaterial.state = enable
  entry/src/main/ets/
    entryability/EntryAbility.ets   窗口沉浸 + 避让区 watcher + 内容加载
    harmony/AvoidAreaWatcher.ets    避让区读取与订阅
    harmony/HarmonySystem.ets       能力自述 / 查询接口
    components/WorkspaceBottomBar.ets  原生底栏（系统符号 + 系统材质）
    pages/Index.ets                 编排：Flutter 视图 + 原生底栏 + bindSheet
    flutter/BilisailFlutterSurface.ets   FlutterPage 宿主（唯一与引擎版本强绑定的点）
    flutter/FlutterEngineGlue.ets       通道胶水
```

为什么不让 Flutter 画底栏：官方「沉浸光感」的落点是 `uiMaterial.ImmersiveMaterial` /
`.systemMaterial()`（API 26.0.0），它**只作用于 ArkUI 组件**。Flutter 自绘的像素无论怎么模糊，
都拿不到系统材质。要让底栏具备真正的沉浸光感，只有把它交给 ArkUI。

Dart 侧通过 `bilisail/harmony_system` 的 `describe()` 得知 `hostsBottomBar`，从而**不重复绘制**
自己的底栏；非鸿蒙平台该标志恒为 false，行为与上游一致。

## 2. 窗口沉浸

```ts
mainWindow.setImmersiveModeEnabledState(true);  // API 12+，同步、无返回值
```

- 它与 `setWindowLayoutFullScreen`（API 9+，返回 Promise）**共享同一状态**，`getImmersiveModeEnabledState()` 可回读。
- 低版本回退路径：抛错时改调 `setWindowLayoutFullScreen(true)`。
- **不要**用 `setWindowSystemBarEnable([])` 判断沉浸是否生效：官方写明它只在窗口全屏/最大化时生效，
  自由窗口设备从 OpenHarmony 5.0.2 起「不生效也不报错」。

## 3. 避让区（底部手势条）

```ts
const system = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);       // 状态栏 + 三键导航
const indicator = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR); // API 11+
bottom = max(system.bottomRect.height, indicator.bottomRect.height) / densityPixels;  // px → vp
```

- 返回值的单位是 **px**，必须换算成 vp 才能用于布局。
- `TYPE_SYSTEM_GESTURE` 官方原文是「当前所有设备均无此类型避让区域」，不要依赖它。
- 必须订阅 `on('avoidAreaChange')`：旋转、折叠、分屏、全屏切换、跨设备流转都会改变避让区。

## 4. 底栏材质与「暗坑」

```ts
.backgroundBlurStyle(BlurStyle.COMPONENT_THICK, { colorMode: ThemeColorMode.SYSTEM, scale: 1.0 })
.systemMaterial(uiMaterial.MaterialType.IMMERSIVE)   // API 26+ 接管
```

- `backgroundBlurStyle` 是所有 API 版本可用的基线；API 26 起系统材质优先于组件自身的背景/模糊/阴影。
- **`expandSafeArea` 不能把底栏铺到手势条下面**：组件设置固定宽高（含 `'auto'`）时只支持
  `[SafeAreaEdge.TOP, SafeAreaEdge.START]`，官方示例图注写明「未扩展至底部导航条」。
  正确做法是窗口级沉浸 + 手动预留 `avoidArea` 高度，本项目的 `WorkspaceBottomBar` 就是这样做的。

## 5. 通道协议

| 方法 | 方向 | 语义 |
| --- | --- | --- |
| `describe` | Dart → ArkTS | 返回 `{apiVersion, hostsBottomBar, immersiveMaterial, immersiveWindow, avoidAreaStream}` |
| `queryAvoidArea` | Dart → ArkTS | 返回 `{bottom, top, sources}`，单位 vp |
| `applyImmersiveLayout` | Dart → ArkTS | 重新打开窗口沉浸 |
| `bilisail/harmony_system/avoid_area` | ArkTS → Dart | EventChannel，避让区变化时推一次 |

**已移除** `setNavigationIndicatorVisible(bool)`：系统没有隐藏底部手势条的公开接口，保留它只会「假成功」。

## 6. 构建

```bash
# 需要 DevEco Studio（含 HarmonyOS SDK）与 @ohos/flutter_ohos 的 har
cd harmony
hvigorw assembleHap --mode module -p product=default
```

`entry/src/main/ets/flutter/BilisailFlutterSurface.ets` 里的 `FlutterPage` 组件名依赖所用 har 版本
（部分版本导出 `FlutterView`），**这是唯一需要按引擎版本调整的文件**。

## 7. 一次开发多端部署

| 层 | 手机 | 平板 | 2in1 | 说明 |
| --- | --- | --- | --- | --- |
| 底栏位置 | 底部 | 底部（`Tabs.barPosition = End`） | 侧栏（`vertical: true`） | ArkUI 断点 `@Env(BREAK_POINT)`（API 22+） |
| 断点阈值 | XS/SM/MD/LG/XL = 320/600/840/1440 | 同左 | 同左 | 官方明确阈值可能被厂商调整，**不要硬编码** |
| 内容布局 | Flutter 自适应 | 同 | 同 | 复用上游 `WindowSizePolicy` |

ArkUI 侧只负责壳与材质，业务布局仍然复用 Flutter 的同一套响应式规则，这是"一次开发多端部署"在本项目
的落地方式：**同一份业务代码 + 两份薄的平台壳**。
C:\Users\16857\Desktop\dsh\_bilisail\harmony-build-add.mdC:\Users\16857\Desktop\dsh\_bilisail\agc-note.mdC:\Users\16857\Desktop\dsh\_bilisail\har-doc.md