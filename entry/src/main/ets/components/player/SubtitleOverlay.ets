import { PlaybackSession } from '../../domain/playback/PlaybackSession';
import { SubtitleCue } from '../../services/SubtitleService';

/**
 * ArkUI subtitle overlay that renders timed text cues at the bottom of the video.
 *
 * Android uses a full subtitle engine (`DefaultSubtitleEngine` with `FormatSRT` /
 * `FormatASS` / `FormatSTL` parsers). This component provides SRT/VTT rendering
 * with configurable text size, delay, and style. It polls
 * `PlaybackSession.currentPositionMs` on its own timer.
 */
@Component
export struct SubtitleOverlay {
  session: PlaybackSession = new PlaybackSession();
  cues: SubtitleCue[] = [];
  visible: boolean = false;
  fontSize: number = 24;
  delayMs: number = 0;
  styleIndex: number = 0;

  @State currentText: string = '';
  private timer: number = -1;

  aboutToAppear(): void {
    this.timer = setInterval(() => this.scan(), 200);
  }

  aboutToDisappear(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  /** Called by parent when cues change (new episode). */
  reset(): void {
    this.currentText = '';
  }

  private scan(): void {
    if (!this.visible || this.cues.length === 0) {
      if (this.currentText.length > 0) {
        this.currentText = '';
      }
      return;
    }
    const pos = this.session.currentPositionMs + this.delayMs;
    let found = '';
    for (const cue of this.cues) {
      if (pos >= cue.startMs && pos <= cue.endMs) {
        found = cue.text;
        break;
      }
    }
    if (found !== this.currentText) {
      this.currentText = found;
    }
  }

  private textColor(): string {
    const colors = ['#FFFFFF', '#FFFF00', '#00FF00', '#00BFFF', '#FF69B4'];
    return colors[this.styleIndex % colors.length];
  }

  private shadowColor(): string {
    const shadows = ['#000000', '#000000', '#003300', '#000033', '#330033'];
    return shadows[this.styleIndex % shadows.length];
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.currentText.length > 0) {
        Text(this.currentText)
          .fontSize(this.fontSize)
          .fontColor(this.textColor())
          .textShadow({
            radius: 3,
            color: this.shadowColor(),
            offsetX: 1,
            offsetY: 1
          })
          .textAlign(TextAlign.Center)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding({ left: 24, right: 24, bottom: 8, top: 8 })
          .backgroundColor('rgba(0,0,0,0.5)')
          .borderRadius(6)
          .margin({ bottom: 80 })
      }
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
    .visibility(this.visible ? Visibility.Visible : Visibility.Hidden)
  }
}
