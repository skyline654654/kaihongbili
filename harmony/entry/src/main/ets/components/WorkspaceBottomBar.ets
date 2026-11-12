import { uiMaterial } from '@kit.ArkUI';

/** 底栏上的一个目的项。 */
export interface BottomBarItem {
  id: string;
  label: string;
  symbol: Resource;
  selectedSymbol: Resource;
}

/**
 * 开鸿哔哩的鸿蒙原生底栏（悬浮胶囊样式）。
 *
 * 与手机版 B 站一致的三点在实现层面都要靠**布局**而不是只靠材质：
 * 1. 悬浮：底栏不贴屏幕左右边、不贴底边，四周留 12vp 外边距并裁成圆角胶囊；
 * 2. 沉浸光感：交给系统材质 —— `.systemMaterial(IMMERSIVE)`（API 26+，模块级开关见
 *    module.json5 的 ohos.arkui.UIMaterial.state=enable），低版本由 `.backgroundBlurStyle`
 *    兜底，二者都要求底栏**下方有内容可模糊**，因此底栏必须是覆盖在内容上的层（Stack），
 *    不能挤在 Column 里把内容顶上去；
 * 3. 中间「+」抬起：用 offset 向上溢出 14vp，并加投影，形成浮起的按钮。
 */
@Component
export struct WorkspaceBottomBar {
  @Prop items: BottomBarItem[];
  @Prop selectedIndex: number;
  @Prop avoidBottom: number;
  onSelect: (index: number) => void = () => {};
  onCreate: () => void = () => {};

  @Builder
  private destinationSlot(item: BottomBarItem, index: number) {
    Column() {
      SymbolGlyph(index === this.selectedIndex ? item.selectedSymbol : item.symbol)
        .fontSize(22)
        .fontColor([index === this.selectedIndex ? $r('sys.color.font_primary') : $r('sys.color.font_secondary')])
      Text(item.label)
        .fontSize(10)
        .margin({ top: 2 })
        .fontColor(index === this.selectedIndex
          ? $r('sys.color.font_primary')
          : $r('sys.color.font_secondary'))
    }
    .layoutWeight(1)
    .height(56)
    .justifyContent(FlexAlign.Center)
    .accessibilityText(item.label)
    .onClick(() => {
      this.onSelect(index);
    })
  }

  /** 中间「+」：向上溢出胶囊，形成抬起的主色按钮。 */
  @Builder
  private createSlot() {
    Column() {
      Stack() {
        Circle()
          .width(52)
          .height(52)
          .fill($r('sys.color.brand'))
          .shadow({ radius: 16, color: '#33000000', offsetY: 4 })
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(26)
          .fontColor([Color.White])
      }
      .width(52)
      .height(52)
      .align(Alignment.Center)
    }
    .width(72)
    .height(56)
    .justifyContent(FlexAlign.Center)
    .offset({ y: -14 })
    .accessibilityText('创作')
    .onClick(() => {
      this.onCreate();
    })
  }

  build() {
    Row() {
      ForEach(this.items, (item: BottomBarItem, index: number) => {
        if (index === Math.floor(this.items.length / 2)) {
          this.createSlot()
        }
        this.destinationSlot(item, index)
      }, (item: BottomBarItem) => item.id)
    }
    .height(56)
    .width('100%')
    // 悬浮：左右与底部各留 12vp，裁成高度 56 的胶囊。
    .margin({ left: 12, right: 12, bottom: 12 + this.avoidBottom })
    .borderRadius(28)
    .clip(true)
    // 基线材质（全 API 可用）：让底下的内容透出一点并模糊。
    .backgroundBlurStyle(BlurStyle.COMPONENT_THICK, {
      colorMode: ThemeColorMode.SYSTEM,
      adaptiveColor: AdaptiveColor.DEFAULT,
      scale: 1.0
    })
    // 极淡的染色，避免纯白内容下看起来像“没材质”。
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .opacity(1)
    // API 26+ 的官方沉浸光感材质（模块级开关在 module.json5）。
    .systemMaterial(uiMaterial.MaterialType.IMMERSIVE)
    .shadow({ radius: 24, color: '#33000000', offsetY: 6 })
  }
}