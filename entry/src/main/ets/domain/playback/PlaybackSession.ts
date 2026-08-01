import media from '@ohos.multimedia.media';
import { MediaSourceRequest, MediaTrack } from './PlaybackModels';
import { errorMessage } from '../../utils/ErrorUtil';

/**
 * Owns a single `AVPlayer` instance.
 *
 * This replaces the ArkUI `Video` component used previously. `Video` cannot send custom
 * request headers, which broke every Referer/User-Agent protected source, WebDAV Basic auth,
 * and Android `livePlayHeaders` rules. `media.createMediaSourceWithUrl(url, headers)` supports
 * them, matching the Android `VideoView.setUrl(url, headers)` behavior.
 */
export class PlaybackSession {
  private player?: media.AVPlayer;
  private surfaceId: string = '';
  private pendingRequest?: MediaSourceRequest;
  private preparing: boolean = false;
  private released: boolean = false;
  private seekTargetMs: number = 0;
  private speed: number = 1.0;
  private scaleType: media.VideoScaleType = media.VideoScaleType.VIDEO_SCALE_TYPE_FIT;

  /** Last reported playback position; read by DanmuOverlay/SubtitleOverlay timers. */
  currentPositionMs: number = 0;

  onStateChange: (state: string) => void = () => {};
  onTimeUpdate: (positionMs: number) => void = () => {};
  onDurationUpdate: (durationMs: number) => void = () => {};
  onError: (message: string) => void = () => {};
  onEndOfStream: () => void = () => {};
  onTracksReady: (audio: MediaTrack[], subtitle: MediaTrack[]) => void = () => {};

  /** The XComponent surface must exist before `prepare()`, otherwise video renders nowhere. */
  async attachSurface(surfaceId: string): Promise<void> {
    this.surfaceId = surfaceId;
    if (this.pendingRequest !== undefined) {
      const request: MediaSourceRequest = this.pendingRequest;
      this.pendingRequest = undefined;
      await this.setSource(request);
    }
  }

  hasSurface(): boolean {
    return this.surfaceId.length > 0;
  }

  async setSource(request: MediaSourceRequest): Promise<void> {
    if (request.url.length === 0) {
      return;
    }
    if (this.surfaceId.length === 0) {
      // Defer until the render surface exists; `attachSurface` replays it.
      this.pendingRequest = request;
      return;
    }
    this.released = false;
    this.seekTargetMs = request.startPositionMs;
    await this.resetPlayer();
    try {
      const player: media.AVPlayer = await this.ensurePlayer();
      const source: media.MediaSource = media.createMediaSourceWithUrl(request.url, request.headers);
      this.preparing = true;
      await player.setMediaSource(source);
    } catch (error) {
      this.preparing = false;
      this.onError(errorMessage(error as Error));
    }
  }

  private async ensurePlayer(): Promise<media.AVPlayer> {
    if (this.player !== undefined) {
      return this.player;
    }
    const player: media.AVPlayer = await media.createAVPlayer();
    this.player = player;
    this.bindEvents(player);
    return player;
  }

  private bindEvents(player: media.AVPlayer): void {
    player.on('stateChange', (state: string) => {
      this.onStateChange(state);
      if (state === 'initialized') {
        player.surfaceId = this.surfaceId;
        player.prepare().catch((error: Error) => {
          this.preparing = false;
          this.onError(errorMessage(error));
        });
        return;
      }
      if (state === 'prepared') {
        this.preparing = false;
        player.videoScaleType = this.scaleType;
        this.applySpeed(player);
        this.onDurationUpdate(player.duration);
        this.loadTracks(player);
        if (this.seekTargetMs > 0) {
          player.seek(this.seekTargetMs, media.SeekMode.SEEK_CLOSEST);
          this.seekTargetMs = 0;
        }
        player.play().catch((error: Error) => this.onError(errorMessage(error)));
      }
    });
    player.on('timeUpdate', (time: number) => {
      this.currentPositionMs = time;
      this.onTimeUpdate(time);
    });
    player.on('durationUpdate', (duration: number) => this.onDurationUpdate(duration));
    player.on('endOfStream', () => this.onEndOfStream());
    player.on('error', (error: Error) => {
      this.preparing = false;
      this.onError(errorMessage(error));
    });
  }

  private loadTracks(player: media.AVPlayer): void {
    player.getTrackDescription().then((descriptions: media.MediaDescription[]) => {
      const audio: MediaTrack[] = [];
      const subtitle: MediaTrack[] = [];
      for (const item of descriptions) {
        const index: number = Number(item[media.MediaDescriptionKey.MD_KEY_TRACK_INDEX] ?? -1);
        const type: number = Number(item[media.MediaDescriptionKey.MD_KEY_TRACK_TYPE] ?? -1);
        const language: string = String(item[media.MediaDescriptionKey.MD_KEY_LANGUAGE] ?? '');
        const name: string = String(item[media.MediaDescriptionKey.MD_KEY_TRACK_NAME] ?? '');
        const mime: string = String(item[media.MediaDescriptionKey.MD_KEY_CODEC_MIME] ?? '');
        const label: string = name.length > 0 ? name : (language.length > 0 ? language : `轨道 ${index}`);
        if (type === media.MediaType.MEDIA_TYPE_AUD) {
          audio.push(new MediaTrack(index, label, language, mime));
        } else if (type === media.MediaType.MEDIA_TYPE_SUBTITLE) {
          subtitle.push(new MediaTrack(index, label, language, mime));
        }
      }
      this.onTracksReady(audio, subtitle);
    }).catch(() => {
      this.onTracksReady([], []);
    });
  }

  private async resetPlayer(): Promise<void> {
    const player: media.AVPlayer | undefined = this.player;
    if (player === undefined) {
      return;
    }
    try {
      await player.reset();
    } catch (_error) {
      // A reset failure means the player is unusable; drop it so the next setSource recreates it.
      this.player = undefined;
    }
  }

  play(): void {
    this.player?.play().catch((error: Error) => this.onError(errorMessage(error)));
  }

  pause(): void {
    this.player?.pause().catch((error: Error) => this.onError(errorMessage(error)));
  }

  seek(positionMs: number): void {
    const target: number = positionMs < 0 ? 0 : Math.floor(positionMs);
    if (this.preparing || this.player === undefined) {
      this.seekTargetMs = target;
      return;
    }
    this.player.seek(target, media.SeekMode.SEEK_CLOSEST);
  }

  setSpeed(speed: number): void {
    this.speed = speed;
    if (this.player !== undefined) {
      this.applySpeed(this.player);
    }
  }

  private applySpeed(player: media.AVPlayer): void {
    player.setSpeed(PlaybackSession.toPlaybackSpeed(this.speed));
  }

  /** Android exposes free-form speed; HarmonyOS AVPlayer only accepts the fixed enum steps. */
  static toPlaybackSpeed(speed: number): media.PlaybackSpeed {
    if (speed <= 0.125) {
      return media.PlaybackSpeed.SPEED_FORWARD_0_125_X;
    }
    if (speed <= 0.25) {
      return media.PlaybackSpeed.SPEED_FORWARD_0_25_X;
    }
    if (speed <= 0.5) {
      return media.PlaybackSpeed.SPEED_FORWARD_0_50_X;
    }
    if (speed <= 0.75) {
      return media.PlaybackSpeed.SPEED_FORWARD_0_75_X;
    }
    if (speed <= 1.0) {
      return media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
    }
    if (speed <= 1.25) {
      return media.PlaybackSpeed.SPEED_FORWARD_1_25_X;
    }
    if (speed <= 1.5) {
      return media.PlaybackSpeed.SPEED_FORWARD_1_50_X;
    }
    if (speed <= 1.75) {
      return media.PlaybackSpeed.SPEED_FORWARD_1_75_X;
    }
    if (speed <= 2.0) {
      return media.PlaybackSpeed.SPEED_FORWARD_2_00_X;
    }
    return media.PlaybackSpeed.SPEED_FORWARD_3_00_X;
  }

  /**
   * Android has 6 scale modes; HarmonyOS AVPlayer exposes 3.
   * Android 0 默认/4 原始 -> FIT, 3 填充/5 裁剪 -> FIT_CROP, 1 16:9 / 2 4:3 -> SCALED_ASPECT.
   */
  static toScaleType(androidScale: number): media.VideoScaleType {
    if (androidScale === 3 || androidScale === 5) {
      return media.VideoScaleType.VIDEO_SCALE_TYPE_FIT_CROP;
    }
    if (androidScale === 1 || androidScale === 2) {
      return media.VideoScaleType.VIDEO_SCALE_TYPE_SCALED_ASPECT;
    }
    return media.VideoScaleType.VIDEO_SCALE_TYPE_FIT;
  }

  setScale(androidScale: number): void {
    this.scaleType = PlaybackSession.toScaleType(androidScale);
    if (this.player !== undefined) {
      this.player.videoScaleType = this.scaleType;
    }
  }

  selectTrack(index: number): void {
    if (index < 0) {
      return;
    }
    this.player?.selectTrack(index).catch(() => {});
  }

  deselectTrack(index: number): void {
    if (index < 0) {
      return;
    }
    this.player?.deselectTrack(index).catch(() => {});
  }

  async addSubtitle(url: string): Promise<void> {
    if (url.length === 0 || this.player === undefined) {
      return;
    }
    await this.player.addSubtitleFromUrl(url);
  }

  async release(): Promise<void> {
    if (this.released) {
      return;
    }
    this.released = true;
    this.pendingRequest = undefined;
    const player: media.AVPlayer | undefined = this.player;
    this.player = undefined;
    if (player !== undefined) {
      try {
        await player.release();
      } catch (_error) {
        // Releasing an already-dead player is not actionable.
      }
    }
  }
}
