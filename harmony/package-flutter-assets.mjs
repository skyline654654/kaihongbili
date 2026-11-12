#!/usr/bin/env node
// 把 Flutter 内容产物打进 HAP：flutter build bundle → 拷贝 rawfile → hvigor 构建 → 官方工具签名。
//
// 背景：只把引擎 har 打进 HAP 是不够的。引擎起来后要找
// resources/rawfile/flutter_assets/{kernel_blob.bin,AssetManifest.bin,...}，
// 没有这些文件时 ArkUI 壳能显示、内容区却是空白（实测）。
//
// 为什么需要 stub ANDROID_HOME：`flutter build bundle` 会跑 native-assets 钩子，
// 钩子在没有 Android SDK 的机器上直接 `Target build_hooks failed: Android SDK could not be found`。
// 这里是 OHOS 构建，并不需要真的 Android SDK，用一个只含目录骨架的 stub 让它通过即可。
//
// 用法：
//   node harmony/package-flutter-assets.mjs
// 环境变量：
//   FLUTTER_ROOT   Flutter SDK 路径（默认 _bilisail/flutter-sdk/flutter）
//   OHOS_CLI       HarmonyOS Command Line Tools 路径
//   JDK_HOME       JDK 17 路径
//   HAP_PASSWORD   keystore 口令（签名用）
import { execFileSync } from 'node:child_process';
import { cpSync, existsSync, mkdirSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repo = join(here, '..');
const flutter = process.env.FLUTTER_ROOT || 'C:/Users/16857/Desktop/dsh/_bilisail/flutter-sdk/flutter';
const cli = process.env.OHOS_CLI || 'C:/Users/16857/Desktop/dsh/_bilisail/harmony-cli/command-line-tools';
const jdk = process.env.JDK_HOME || 'C:/Users/16857/Desktop/dsh/_bilisail/jdk/jdk-17.0.21.0.2+1';

const stub = join(repo, '.android-sdk-stub');
for (const d of ['platforms/android-34', 'build-tools/34.0.0', 'licenses']) mkdirSync(join(stub, d), { recursive: true });

const env = { ...process.env, ANDROID_HOME: stub, ANDROID_SDK_ROOT: stub, CI: 'true', FLUTTER_SUPPRESS_ANALYTICS: 'true' };
console.log('• flutter build bundle');
execFileSync(join(flutter, 'bin', process.platform === 'win32' ? 'flutter.bat' : 'flutter'),
  ['--suppress-analytics', 'build', 'bundle'], { cwd: repo, stdio: 'inherit', env, shell: process.platform === 'win32' });

const src = join(repo, 'build', 'flutter_assets');
if (!existsSync(join(src, 'kernel_blob.bin')) && !existsSync(join(src, 'AssetManifest.bin'))) {
  console.error('missing build/flutter_assets'); process.exit(1);
}
const dst = join(here, 'entry', 'src', 'main', 'resources', 'rawfile', 'flutter_assets');
mkdirSync(dst, { recursive: true });
cpSync(src, dst, { recursive: true, force: true });
console.log('• assets copied:', readdirSync(dst).length, 'entries');

console.log('• hvigorw assembleHap');
execFileSync(join(cli, 'bin', process.platform === 'win32' ? 'hvigorw.bat' : 'hvigorw'),
  ['assembleHap', '--no-daemon'], { cwd: here, stdio: 'inherit', shell: process.platform === 'win32', env: { ...env, JAVA_HOME: jdk } });

console.log('• sign');
const jar = join(cli, 'sdk', 'default', 'openharmony', 'toolchains', 'lib', 'hap-sign-tool.jar');
const unsigned = join(here, 'entry', 'build', 'default', 'outputs', 'default', 'entry-default-unsigned.hap');
const signed = join(here, 'dist', 'kaihongbili-signed.hap');
mkdirSync(join(here, 'dist'), { recursive: true });
execFileSync(join(jdk, 'bin', process.platform === 'win32' ? 'java.exe' : 'java'), ['-jar', jar,
  'sign-app', '-mode', 'localSign', '-keyAlias', 'bilisail', '-signAlg', 'SHA256withECDSA',
  '-appCertFile', join(here, 'signature', 'bilisail-release.cer'),
  '-profileFile', join(here, 'signature', 'bilisail-release.p7b'),
  '-inFile', unsigned, '-outFile', signed,
  '-keystoreFile', join(here, 'signature', 'debug.p12'),
  '-keyPwd', process.env.HAP_PASSWORD || '', '-keystorePwd', process.env.HAP_PASSWORD || ''],
  { stdio: 'inherit' });
console.log('done ->', signed);
