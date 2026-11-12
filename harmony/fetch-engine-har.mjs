#!/usr/bin/env node
// 下载官方 Flutter-OHOS 引擎 har 并放进 harmony/har/。
//
// 仓库不再内置引擎桩；引擎产物在 OpenHarmony 的 OBS 上，路径规则来自
// flutter_tools 的 ohosStorageBaseUrl + EngineArtifacts：
//   <base>/flutter_infra_release/flutter/<engine.ohos.version>/ohos-arm64/artifacts.zip
// 该 zip 内只有一个文件：flutter.har（内含 libflutter.so）。
//
// 用法：node harmony/fetch-engine-har.mjs  然后按提示解压到 harmony/har/flutter.har
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const version = process.env.OHOS_ENGINE_VERSION || 'a9e521ff880033ab7bfecc6903da552483a506e1';
const base = process.env.FLUTTER_OHOS_STORAGE_BASE_URL || 'https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com';
const url = base + '/flutter_infra_release/flutter/' + version + '/ohos-arm64/artifacts.zip';

console.log('GET', url);
const r = await fetch(url, { signal: AbortSignal.timeout(600000) });
if (r.status !== 200) { console.error('HTTP', r.status); process.exit(1); }
const zip = Buffer.from(await r.arrayBuffer());
const zipPath = join(here, 'artifacts.zip');
writeFileSync(zipPath, zip);
console.log('downloaded', zip.length, 'bytes ->', zipPath);
mkdirSync(join(here, 'har'), { recursive: true });
console.log('extract: tar -xf ' + zipPath + ' -C ' + join(here, 'har'));
