#!/usr/bin/env node
// 把已签名的 HAP 装到已连接的鸿蒙设备上。
//
// 用法：
//   OHOS_CLI=/path/to/command-line-tools node install-hap.mjs [hap路径]
//
// 默认安装在 dist/kaihongbili-signed.hap；release Profile 不含设备 UDID，
// 首次侧载时设备可能要求确认信任该证书链。
import { execFileSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const hap = resolve(
  process.argv[2] || join(here, 'dist', 'kaihongbili-signed.hap'),
);

if (!existsSync(hap)) {
  console.error('找不到 HAP：' + hap);
  process.exit(1);
}

const cli = process.env.OHOS_CLI;
if (!cli) {
  console.error('需要环境变量 OHOS_CLI 指向 HarmonyOS Command Line Tools');
  process.exit(1);
}

const hdc = resolve(
  cli,
  'sdk',
  'default',
  'openharmony',
  'toolchains',
  process.platform === 'win32' ? 'hdc.exe' : 'hdc',
);

let targets = '';
try {
  targets = execFileSync(hdc, ['list', 'targets'], { encoding: 'utf8' });
} catch (error) {
  console.error('hdc 调用失败：' + String(error).slice(0, 200));
  process.exit(1);
}

const device = targets
  .split(/\r?\n/)
  .map((line) => line.trim())
  .find((line) => line.length > 0 && !line.includes('Empty') && !line.startsWith('['));

if (!device) {
  console.error('没有检测到已连接的设备（hdc list targets 为空）。');
  console.error('请先用 USB 连接设备、开启「开发者模式 + USB 调试」，再重跑本脚本。');
  process.exit(2);
}

console.log('目标设备：' + device);
const output = execFileSync(hdc, ['-t', device, 'install', '-r', hap], {
  encoding: 'utf8',
});
console.log(output.trim());
console.log('安装完成。启动：hdc -t ' + device + ' shell aa start -a EntryAbility -b dev.bilisail.client');
