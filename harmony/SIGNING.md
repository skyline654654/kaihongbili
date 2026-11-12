# 签名与调试设备的前置条件

本目录的 `entry-default-unsigned.hap` 是**未签名**包，只能证明构建链路通，不能安装到真机或云调试设备。
要出可安装包，按下面的顺序做（前两步必须在 AppGallery Connect 网页控制台完成，命令行工具做不了）：

## 1. 在 AGC 创建 HarmonyOS 应用（必须先做）

控制台：<https://developer.huawei.com/consumer/cn/service/josp/agc/index.html> → 应用管理 → 所有应用 → 创建应用。
2026-11-02 实测该账号（白日梦想家 / 刘健征，已实名）当前 **HarmonyOS 应用数 = 0**，所以云调试/真机都没法申请。

创建时填这些值，必须与工程一致：

| 字段 | 值 |
| --- | --- |
| 应用名称 | 哔帆 / BiliSail |
| 应用包名 | `dev.bilisail.client`（= `AppScope/app.json5` 的 bundleName，改一边必须改另一边） |
| 应用类型 | 应用（不是元服务） |
| 支持设备 | 手机、平板（可选 2in1） |
| 应用分类 | 影音娱乐 → 视频播放 |
| 默认语言 | 简体中文 |


### 已创建（2026-11-02 实测）

| 字段 | 值 |
| --- | --- |
| 应用名称 | 开鸿哔哩 |
| APP ID | 6917620749510987805 |
| 应用包名 | dev.bilisail.client |
| 支持设备 | 手机 / 平板 |
| 应用分类 | 应用 |
| 应用所属项目 | BiliSail |

AGC 拒绝包名里的保留词：`dev.bilisail.harmony` 报「包含敏感词或者保留字符 harmony」，
`dev.bilisail.ohos` 报「包含敏感词或者保留字符 ohos」，最终采用 `dev.bilisail.client`；
`AppScope/app.json5` 的 `bundleName` 已同步。

## 2. 生成证书与 Profile

控制台 → 用户与访问 → ID、证书和 Profile：

1. **证书**：新建调试证书，下载 `.cer`、`.p12` 与密码；
2. **Profile**：选“调试”，绑定刚建的应用与调试证书，登记调试设备的 UDID，下载 `.p7b`；
3. 把三者放进 `harmony/signature/`（本目录已 gitignore），再填 `build-profile.json5` 的 `signingConfigs`。

`build-profile.json5` 里的占位：

```json5
"signingConfigs": [
  {
    "name": "default",
    "material": {
      "certpath": "./signature/debug.cer",
      "storePassword": "<加密后的密码>",
      "keyAlias": "<别名>",
      "keyPassword": "<加密后的密码>",
      "profile": "./signature/debug.p7b",
      "signAlg": "SHA256withECDSA",
      "storeFile": "./signature/debug.p12"
    }
  }
]
```

DevEco Studio 会自动把明文密码加密成 `storePassword`/`keyPassword`；命令行构建时需要自己先加密一次。

## 3. 云调试 / 真机

- 云调试：<https://developer.huawei.com/consumer/cn/doc/doccenter-testing/agc-help-clouddebug-applyequip-0000002254916518>
  流程是「申请调试设备 → 上传 HAP → 预约 → 调试」。前提同样是第 1、2 步完成。
- 本地真机：设备开启开发者模式与 USB 调试，`hdc install` 安装已签名 HAP。