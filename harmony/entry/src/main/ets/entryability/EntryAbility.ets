import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { FlutterAbility } from '@ohos/flutter_ohos';
import { AvoidAreaWatcher } from '../harmony/AvoidAreaWatcher';
import { HarmonySystem } from '../harmony/HarmonySystem';

const DOMAIN: number = 0x0B11;
const TAG: string = 'EntryAbility';

/**
 * 开鸿哔哩的鸿蒙入口。
 *
 * 必须继承 `FlutterAbility`（而不是 UIAbility）：引擎、FlutterView 与
 * LocalStorage 里的 `viewId` 都由基类在 onWindowStageCreate 中创建，
 * 页面再通过 `FlutterPage({ viewId })` 把画面挂上去。自己 extends UIAbility 时
 * 引擎根本不会被创建——设备上只会看到空白/占位。
 *
 * 职责边界：
 * 1. 引擎生命周期：交给 FlutterAbility（super 调用）。
 * 2. 窗口级沉浸：setImmersiveModeEnabledState(true)（API 12+），失败回退 setWindowLayoutFullScreen。
 * 3. 避让区：AvoidAreaWatcher 订阅 TYPE_SYSTEM + TYPE_NAVIGATION_INDICATOR，px→vp。
 */
export default class EntryAbility extends FlutterAbility {
  private avoidArea: AvoidAreaWatcher | undefined = undefined;

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 基类负责创建引擎/FlutterView、写入 viewId localStorage 并 loadContent。
    super.onWindowStageCreate(windowStage);

    const mainWindow: window.Window = windowStage.getMainWindowSync();
    this.enableImmersiveWindow(mainWindow);

    this.avoidArea = new AvoidAreaWatcher(mainWindow);
    HarmonySystem.bind(mainWindow, this.avoidArea);
    hilog.info(DOMAIN, TAG, 'flutter ability window ready');
  }

  /**
   * 打开窗口级沉浸。
   * setImmersiveModeEnabledState 是 API 12+ 同步接口；老版本抛错时回退 API 9+ 的 setWindowLayoutFullScreen。
   */
  private enableImmersiveWindow(mainWindow: window.Window): void {
    try {
      mainWindow.setImmersiveModeEnabledState(true);
      hilog.info(DOMAIN, TAG, 'immersive window enabled (API 12+)');
      return;
    } catch (error) {
      const failure = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'setImmersiveModeEnabledState failed: %{public}s', failure.message);
    }
    mainWindow.setWindowLayoutFullScreen(true)
      .then(() => {
        hilog.info(DOMAIN, TAG, 'immersive window enabled (API 9 fallback)');
      })
      .catch((error: BusinessError) => {
        hilog.error(DOMAIN, TAG, 'setWindowLayoutFullScreen failed: %{public}s', error.message);
      });
  }

  onWindowStageDestroy(): void {
    this.avoidArea?.stop();
    this.avoidArea = undefined;
    HarmonySystem.unbind();
    super.onWindowStageDestroy();
    hilog.info(DOMAIN, TAG, 'onWindowStageDestroy');
  }
}