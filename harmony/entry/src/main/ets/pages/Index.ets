import { HarmonySystem } from '../harmony/HarmonySystem';
import { AvoidAreaSides } from '../harmony/AvoidAreaWatcher';
import { BottomBarItem, WorkspaceBottomBar } from '../components/WorkspaceBottomBar';
import { BilisailFlutterSurface } from '../flutter/BilisailFlutterSurface';

// FlutterAbility 在 loadContent 时传入的 LocalStorage，里面带着 viewId。
let storage = LocalStorage.getShared();

/**
 * 鸿蒙侧的主页面：ArkUI 负责「壳」，Flutter 负责「内容」。
 *
 * 布局要点：
 * 1. 内容区吃满整屏（窗口已由 EntryAbility 打开沉浸模式）。
 * 2. 底栏是**原生 ArkUI 组件**，因此能吃到系统「沉浸光感」材质；
 *    Flutter 侧通过 describe() 的 hostsBottomBar 得知不要再画底栏。
 * 3. 底栏高度 = 56vp + 手势条避让高度，由 AvoidAreaWatcher 实时回推。
 */
@Entry(storage)
@Component
struct Index {
  // 由 FlutterAbility 写入；引擎视图靠它挂载。
  @LocalStorageLink('viewId') viewId: string = '';
  @State selectedIndex: number = 0;
  @State avoidBottom: number = 0;
  @State createSheetVisible: boolean = false;

  private items: BottomBarItem[] = [
    {
      id: 'home',
      label: '首页',
      symbol: $r('sys.symbol.house'),
      selectedSymbol: $r('sys.symbol.house_fill')
    },
    {
      id: 'dynamic',
      label: '动态',
      symbol: $r('sys.symbol.square_grid_2x2'),
      selectedSymbol: $r('sys.symbol.square_grid_2x2')
    },
    {
      id: 'shop',
      label: '会员购',
      symbol: $r('sys.symbol.bag'),
      selectedSymbol: $r('sys.symbol.bag_fill')
    },
    {
      id: 'mine',
      label: '我的',
      symbol: $r('sys.symbol.person'),
      selectedSymbol: $r('sys.symbol.person_fill')
    }
  ];

  aboutToAppear(): void {
    const sides: AvoidAreaSides = HarmonySystem.queryAvoidArea();
    this.avoidBottom = sides.bottom;
    HarmonySystem.onAvoidAreaChanged((next: AvoidAreaSides) => {
      // 旋转、折叠、分屏切换都会走这里，底栏随之重新预留高度。
      this.avoidBottom = next.bottom;
    });
  }

  aboutToDisappear(): void {
    HarmonySystem.offAvoidAreaChanged(() => {});
  }

  @Builder
  private createSheetContent() {
    Column({ space: 8 }) {
      Text('创作')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .width('100%')
      List({ space: 8 }) {
        ListItem() {
          this.createEntryRow('视频', '投稿稿件，可选择封面与稿件文件', 'video')
        }
        ListItem() {
          this.createEntryRow('图文', '专栏图文，支持图文混排', 'article')
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private createEntryRow(title: string, description: string, entry: string) {
    Row({ space: 12 }) {
      Column({ space: 2 }) {
        Text(title).fontSize(15).fontWeight(FontWeight.Medium)
        Text(description).fontSize(12).fontColor($r('sys.color.font_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor($r('sys.color.comp_background_tertiary'))
    .onClick(() => {
      this.createSheetVisible = false;
      // 创作页由 Flutter 表单承载，避免两套表单实现漂移。
      HarmonySystem.requestCreateEntry(entry);
    })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 内容区：Flutter 视图填满整屏，底栏浮在它上面。
      BilisailFlutterSurface({ viewId: this.viewId })
        .width('100%')
        .height('100%')

      WorkspaceBottomBar({
        items: this.items,
        selectedIndex: this.selectedIndex,
        avoidBottom: this.avoidBottom,
        onSelect: (index: number) => {
          this.selectedIndex = index;
          HarmonySystem.requestSectionSelect(this.items[index].id);
        },
        onCreate: () => {
          this.createSheetVisible = true;
        }
      })
    }
    .width('100%')
    .height('100%')
    // 系统 bindSheet：与官方「沉浸光感」材质一致的表单页。
    .bindSheet($$this.createSheetVisible, this.createSheetContent(), {
      height: SheetSize.MEDIUM,
      dragBar: true,
      showClose: true,
      preferType: SheetType.BOTTOM
    })
  }
}