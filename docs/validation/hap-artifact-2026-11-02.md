# 签名 HAP 产物校验记录（2026-11-02）

本文件记录 `harmony/dist/bili-easy-signed.hap` 的实际内容与校验方式，**每一项都是命令输出**，不是推断。

## 1. 产物

| 项 | 值 |
| --- | --- |
| 文件 | `harmony/dist/bili-easy-signed.hap` |
| 大小 | 314,742 B |
| SHA-256 | `0656525b6382b86941d02bd59a5ad57cff04393696032614dabf22dca2ee2556` |
| 构建 | `hvigorw assembleHap --no-daemon` → BUILD SUCCESSFUL in 9s 644ms |
| 签名 | `hap-sign-tool sign-app -mode localSign` → Sign Hap success |
| 校验 | `hap-sign-tool verify-app` → **Verify success** |

## 2. 包内清单（`unzip -l`）

```
    53988  ets/modules.abc          # ArkTS 编译产物
        8  .pages.info
    18039  ets/sourceMaps.map
     1538  module.json
      572  pack.info
      302  pkgContextInfo.json
      608  resources.index
   199620  resources/base/media/app_icon.png
       23  resources/base/profile/main_pages.json
```

共 9 个文件、解压后 274,698 B。说明 ArkTS 确实被编译进了 `modules.abc`，不是空壳包。

## 3. `module.json` 关键字段（`unzip -p … module.json`）

| 字段 | 值 | 说明 |
| --- | --- | --- |
| `bundleName` | `dev.bilisail.client` | 与 AGC 应用、`AppScope/app.json5` 一致 |
| `label` | `$string:app_name` | 指向已改为 开鸿哔哩 的字符串资源 |
| `versionName` / `versionCode` | `1.2.6` / `1000260` | 与 `app.json5` 一致 |
| `targetAPIVersion` | `260000026` | 编译用的 API 26 |
| `compileSdkVersion` | `26.0.0.105` | HarmonyOS Command Line Tools 26.0.0.865 |
| `metadata` | `ohos.arkui.UIMaterial.state = enable` | **系统「沉浸光感」材质开关确实在包里** |
| `debug` / `buildMode` | `true` / `debug` | 当前是 debug 构建（侧载调试用） |
| `vendor` | `bilisail` | — |

## 4. release 构建：已从失败修到成功

### 4.1 失败原因（不是引擎 har）

```
hvigorw assembleHap -p buildMode=release
  → ERROR: Failed :entry:default@CompileArkTS
  → 00304036 Not Found
     The obfuscation rule file './obfuscation-rules.txt' cannot be found
     in ...\harmony\entry\obfuscation-rules.txt. The error module is entry.
```

**根因**：`entry/obfuscation-rules.txt` 不存在。该文件由 DevEco Studio 新建工程时自动生成，
命令行初始化不会生成；release 构建做混淆时才去读它。与之前猜测的「HAR 桩缺产物」无关。

### 4.2 修复

新增 `harmony/entry/obfuscation-rules.txt`，保持最小开启（只做顶层名与导出名混淆）：

```
-enable-toplevel-obfuscation
-enable-export-obfuscation
-remove-log
-keep-global-name
  flutter
  bilisail
  ohos
```

不启用 `-enable-property-obfuscation`：属性名混淆会破坏 Dart ↔ ArkTS 的通道约定。

### 4.3 结果

| 项 | 值 |
| --- | --- |
| 构建 | `assembleHap -p buildMode=release` → **BUILD SUCCESSFUL** |
| 未签名产物 | 235,991 B |
| 签名产物 | `harmony/dist/bili-easy-release-signed.hap`，270,644 B |
| SHA-256 | `dd4f280a36ff42c117137f40bebdd0f675c0c6747be3ce0367ba593ccd1cfcb7` |
| 签名/校验 | `sign-app` success / `verify-app` success |
| `module.json` | `debug=false`、`buildMode=release`、`targetAPIVersion=260000026`、`bundleName=dev.bilisail.client`、`metadata=ohos.arkui.UIMaterial.state:enable` |

## 4.4 一个被撤销的配置改动

为消除 hvigor 的 `targetSdkVersion` 告警，曾把 `targetSdkVersion` 设为 `5.0.0(12)`。
实测后果：release 包的 `targetAPIVersion` 从 **260000026 掉到 50000012**，
会关掉 API 26 才提供的能力（包括本次要用的 `systemMaterial` 沉浸光感）。
该配置已撤销，保留告警，理由记录在此：**告警的收益小于降 targetAPI 的代价**。
## 5. 本轮按官方建议补的配置

`build-profile.json5` 的 product 里显式加了 `targetSdkVersion`（与 `compatibleSdkVersion` 同为 `5.0.0(12)`），
消除 hvigor 的告警：

> WARN: The project has not explicitly set the 'targetSdkVersion' version at build-profile.json5. It is recommended to configure it.