import { PlaybackSession } from '../../domain/playback/PlaybackSession';
import { DanmuConfig, DanmuItem } from '../../services/DanmuService';

interface ScrollingDanmu {
  id: number;
  text: string;
  color: string;
  fontSize: number;
  row: number;
  offsetX: number;
}

/**
 * ArkUI danmaku overlay that renders Bilibili-style scrolling comments.
 *
 * Android uses the FlameDanmaku library (`master.flame.danmaku`). This component
 * provides an equivalent using ArkUI `animateTo` + `translate` for right-to-left
 * scrolling text. It polls `PlaybackSession.currentPositionMs` on its own timer
 * to avoid ArkUI `@Prop` limitations with complex types.
 */
@Component
export struct DanmuOverlay {
  session: PlaybackSession = new PlaybackSession();
  items: DanmuItem[] = [];
  config: DanmuConfig = { open: true, maxLine: 3, speed: 1.5, alpha: 0.9, sizeScale: 0.8, randomColor: false };
  visible: boolean = false;

  @State activeItems: ScrollingDanmu[] = [];
  private nextId: number = 0;
  private lastScanMs: number = 0;
  private rowOccupiedUntil: number[] = [];
  private timer: number = -1;

  aboutToAppear(): void {
    this.rowOccupiedUntil = new Array(this.config.maxLine).fill(0);
    this.timer = setInterval(() => this.scan(), 200);
  }

  aboutToDisappear(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  /** Called by parent when items change (new episode). */
  reset(): void {
    this.activeItems = [];
    this.lastScanMs = 0;
    this.rowOccupiedUntil = new Array(this.config.maxLine).fill(0);
  }

  private scan(): void {
    if (!this.visible || !this.config.open || this.items.length === 0) {
      return;
    }
    const pos = this.session.currentPositionMs;
    if (pos < this.lastScanMs) {
      this.lastScanMs = pos;
      this.activeItems = [];
      this.rowOccupiedUntil = new Array(this.config.maxLine).fill(0);
      return;
    }
    const scanStart = this.lastScanMs;
    this.lastScanMs = pos;
    for (const item of this.items) {
      if (item.timeMs > scanStart && item.timeMs <= pos) {
        this.addDanmu(item);
      }
    }
  }

  private addDanmu(item: DanmuItem): void {
    const row = this.findFreeRow();
    if (row < 0) {
      return;
    }
    const id = this.nextId++;
    const fontSize = Math.round(item.size * this.config.sizeScale);
    const colorStr = this.config.randomColor ? this.randomColor() : this.colorToHex(item.color);
    const duration = Math.round(8000 / this.config.speed);
    this.rowOccupiedUntil[row] = Date.now() + duration * 0.6;
    const scrolling: ScrollingDanmu = {
      id,
      text: item.text,
      color: colorStr,
      fontSize,
      row,
      offsetX: 110
    };
    this.activeItems = this.activeItems.concat([scrolling]);
    setTimeout(() => this.animateItem(id, duration), 50);
  }

  private animateItem(id: number, duration: number): void {
    animateTo({ duration, curve: Curve.Linear, iterations: 1 }, () => {
      this.activeItems = this.activeItems.map((item: ScrollingDanmu) => {
        if (item.id === id) {
          return { id: item.id, text: item.text, color: item.color, fontSize: item.fontSize, row: item.row, offsetX: -110 };
        }
        return item;
      });
    });
    setTimeout(() => this.removeItem(id), duration + 200);
  }

  private removeItem(id: number): void {
    this.activeItems = this.activeItems.filter((item: ScrollingDanmu) => item.id !== id);
  }

  private findFreeRow(): number {
    const now = Date.now();
    for (let i = 0; i < this.config.maxLine; i++) {
      if (this.rowOccupiedUntil[i] === undefined || this.rowOccupiedUntil[i] <= now) {
        return i;
      }
    }
    return -1;
  }

  private colorToHex(color: number): string {
    const r = (color >> 16) & 0xFF;
    const g = (color >> 8) & 0xFF;
    const b = color & 0xFF;
    return `#${this.toHex2(r)}${this.toHex2(g)}${this.toHex2(b)}`;
  }

  private toHex2(value: number): string {
    return value < 16 ? `0${value.toString(16)}` : value.toString(16);
  }

  private randomColor(): string {
    const colors = ['#FFFFFF', '#FE0302', '#FF7204', '#FFFF00', '#00CD00', '#00BFFF', '#CC44CC', '#9B30FF'];
    return colors[Math.floor(Math.random() * colors.length)];
  }

  private rowTopY(row: number): number {
    return 20 + row * 38;
  }

  build() {
    Stack({ alignContent: Alignment.Start }) {
      ForEach(this.activeItems, (item: ScrollingDanmu) => {
        Text(item.text)
          .fontSize(item.fontSize)
          .fontColor(item.color)
          .fontWeight(FontWeight.Medium)
          .translate({ x: `${item.offsetX}%` })
          .position({ y: this.rowTopY(item.row) })
          .opacity(this.config.alpha)
      }, (item: ScrollingDanmu) => `${item.id}`)
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
    .visibility(this.visible && this.config.open ? Visibility.Visible : Visibility.Hidden)
  }
}
