import { FlutterPage } from '@ohos/flutter_ohos';

/**
 * Flutter 视图在 ArkUI 里的宿主。
 *
 * `viewId` 由 FlutterAbility 创建 FlutterView 后写进 LocalStorage，
 * 页面通过 @LocalStorageLink 取到再传进来；不传 viewId 时 FlutterPage 找不到视图。
 */
@Component
export struct BilisailFlutterSurface {
  @Prop viewId: string = '';

  build() {
    FlutterPage({ viewId: this.viewId })
      .width('100%')
      .height('100%')
  }
}
