/**
 * Player contracts shared by VOD playback (Play page) and live playback (Live page).
 * Mirrors the Android `VideoView` + `VodController` surface that both screens rely on.
 */

export class MediaSourceRequest {
  url: string = '';
  headers: Record<string, string> = {};
  startPositionMs: number = 0;

  constructor(url: string, headers: Record<string, string> = {}, startPositionMs: number = 0) {
    this.url = url;
    this.headers = headers;
    this.startPositionMs = startPositionMs;
  }
}

export class MediaTrack {
  index: number = -1;
  label: string = '';
  language: string = '';
  mime: string = '';

  constructor(index: number, label: string, language: string, mime: string) {
    this.index = index;
    this.label = label;
    this.language = language;
    this.mime = mime;
  }
}

/** Android `PlayerHelper.getScaleName` order. Android: 0 默认 1 16:9 2 4:3 3 填充 4 原始 5 裁剪 */
export const ScaleNames: string[] = ['默认', '16:9', '4:3', '填充', '原始', '裁剪'];

/** Android `VodController` speed steps. */
export const SpeedValues: number[] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0];

export function speedLabel(speed: number): string {
  return `${speed}X`;
}
