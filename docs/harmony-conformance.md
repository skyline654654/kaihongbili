# 鸿蒙官方接口符合性清单

本文件逐条列出适配中实际使用的鸿蒙接口，标注官方文档依据、代码位置与验证方式。
未核实的项单独列出，不写成结论。API 依据主要来自 gitee `openharmony/docs`（CC-BY-4.0），
逐条原文摘录见 [鸿蒙 API 调研记录](research/harmonyos-api-notes.md)。

## 1. 已使用（有代码位置、有验证）

| 能力 | 官方接口 | API 版本 | 代码位置 | 验证 |
| --- | --- | --- | --- | --- |
| 窗口沉浸 | `setImmersiveModeEnabledState(true)`，失败回退 `setWindowLayoutFullScreen(true)` | 12+ / 9+ | `entryability/EntryAbility.ets` | ArkTS 编译通过 + HAP 构建成功；**未实机验证** |
| 避让区读取 | `getWindowAvoidArea(TYPE_SYSTEM / TYPE_NAVIGATION_INDICATOR)` | 9+ / 11+ | `harmony/AvoidAreaWatcher.ets` | px→vp 按 `display.densityPixels` 换算 |
| 避让区变化 | `on/off('avoidAreaChange')` | 9+ | 同上 | 订阅在 `start()`、退订在 `stop()`，UIAbility 销毁时调用 |
| 系统材质（沉浸光感） | `.systemMaterial()` + `module.json5` 的 `ohos.arkui.UIMaterial.state=enable` | 26.0.0 | `components/WorkspaceBottomBar.ets`、`entry/src/main/module.json5` | 元数据已声明；低于 API 26 由 `backgroundBlurStyle` 兜底 |
| 基线模糊 | `.backgroundBlurStyle(BlurStyle.COMPONENT_THICK, { colorMode, adaptiveColor, scale })` | 9+ | 同上 | 全版本可用的降级材质 |
| 系统符号 | `SymbolGlyph` + `sys.symbol.*` 资源 | 11+ | 同上、`pages/Index.ets` | 编译期会校验资源名（`dot_square` 不存在时报错，已改 `square_grid_2x2`） |
| 系统半模态 | `bindSheet`（`SheetSize.MEDIUM` / `SheetType.BOTTOM`） | 11+ | `pages/Index.ets` | 编译通过 |

## 2. 明确不使用（并说明原因）

| 官方接口 | 为什么不用 |
| --- | --- |
| `setWindowSystemBarEnable([])` | 官方写明只在窗口**全屏/最大化**时生效；自由窗口设备从 OpenHarmony 5.0.2 起「不生效也不报错」，无法用返回值判断 |
| 用 `expandSafeArea` 把底栏铺到手势条下 | 组件设置固定宽高（含 `auto`）时只支持 `SafeAreaEdge.TOP/START`，官方示例图注写明「未扩展至底部导航条」 |
| `setNavigationIndicatorVisible(bool)` | 系统没有隐藏底部手势条的公开接口，保留它只会「假成功」；已从通道移除 |
| `AvoidAreaType.TYPE_SYSTEM_GESTURE` | 官方原文「当前所有设备均无此类型避让区域」，不可依赖 |

## 3. 官方优化清单

| 优化 | 状态 | 落点 |
| --- | --- | --- |
| 沉浸式窗口 + 手势条避让 | 已实现 | `EntryAbility.ets` + `AvoidAreaWatcher.ets` |
| 系统「沉浸光感」材质（而非自绘模糊） | 已实现 | `module.json5` metadata + `WorkspaceBottomBar.ets` |
| 底栏用系统符号与系统组件 | 已实现 | `components/`、`pages/` |
| 转场中禁用实时模糊、过渡层独立 `RepaintBoundary` | 已实现（Flutter 侧） | `lib/shared/ui/cover_flight.dart` |
| 尊重系统「减弱动效」 | 已实现 | 同一文件 + `MediaQuery.disableAnimationsOf` |
| 图片按目标尺寸解码 | 已实现（上游既有） | `lib/core/presentation/app_image_provider.dart` |
| 构建严格模式 `strictMode` | 已实现 | `harmony/build-profile.json5` |
| release 构建（混淆规则 `-remove-log`、保留通道名） | 已实现 | `harmony/entry/obfuscation-rules.txt` |
| `systemBarEffect` 智能反色 | **待办** | 需 API 12+ 真机验证后再开 |
| ArkUI 页面预加载 | **待办** | 内容全在 Flutter 内，壳层无独立页面可预加载 |
| ArkUI 断点响应式 | **部分** | 现用 Flutter `WindowSizePolicy`；壳层只按避让区响应 |

## 4. 构建与工具链（官方 CLI，非 DevEco）

| 步骤 | 命令 | 结果 |
| --- | --- | --- |
| 依赖安装 | `ohpm install` | completed |
| 资源与 ArkTS 编译 | `hvigorw assembleHap --no-daemon` | **BUILD SUCCESSFUL**，产物 `entry-default-unsigned.hap`（275,635 B） |
| 代码检查 | `codelinter entry/src/main/ets` | Errors: 0 / Warns: 2（均为「自定义组件建议改 @Builder」） |

前置：HarmonyOS Command Line Tools 26.0.0.865 + JDK 17；`hvigor/hvigor-config.json5` 与 `local.properties`
需手补（DevEco 会自动生成），见 `docs/harmony-adaptation.md` 第 8 节。

## 5. 未验证项（不得当作已通过）

- 任何真机 / 云调试运行结果；
- `systemMaterial` 的实际视觉效果（需 API 26 设备）；
- `avoidAreaChange` 在折叠屏 / 分屏下的回推时序；
- 安装与运行（签名已完成，但尚未在真机/云设备上安装）。

## 6. 签名链路现状

| 步骤 | 状态 |
| --- | --- |
| AGC 应用 | 已建：开鸿哔哩 / APP ID 6917620749510987805 / dev.bilisail.client |
| 调试证书 | 已建：bilisail-debug（生效，2027-11-03），已下载 `harmony/signature/bilisail-debug.cer` |
| 私钥 | 本机 keytool 生成 `harmony/signature/debug.p12`（EC P-256） |
| 发布证书 | 已建：`bilisail-release`（生效，2029-11-03），已下载 `signature/bilisail-release.cer` |
| 发布 Profile | 已建：`bilisail-release`（发布 / dev.bilisail.client / 开鸿哔哩），已下载 `signature/bilisail-release.p7b` |
| **签名 HAP** | **已产出并校验通过**：`entry-default-signed.hap`（314,749 B），`hap-sign-tool verify-app` 返回 Verify success |
| 安装到设备 | 未做（发布 Profile 不含设备 UDID；侧载需设备信任该证书链） |