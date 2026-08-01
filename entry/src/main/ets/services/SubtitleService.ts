import { HttpClient } from './HttpClient';
import { errorMessage } from '../utils/ErrorUtil';

/**
 * A single subtitle cue with start/end times and text.
 *
 * Android uses a full subtitle engine (FormatSRT/FormatASS/FormatSTL) with a
 * TimedTextObject. We implement SRT and VTT parsing (the two most common web
 * formats) and render with a simple ArkUI Text overlay.
 */
export interface SubtitleCue {
  startMs: number;
  endMs: number;
  text: string;
}

export class SubtitleService {
  private readonly httpClient: HttpClient = new HttpClient();

  /**
   * Resolves the subtitle source and parses it into SubtitleCue[].
   *
   * The `source` can be an HTTP/HTTPS URL or a raw subtitle string.
   * Format is detected by content: SRT (`1\n00:00:01,000 --> 00:00:04,000\nText`)
   * or VTT (`WEBVTT\n\n00:00:01.000 --> 00:00:04.000\nText`).
   */
  async load(source: string): Promise<SubtitleCue[]> {
    const trimmed = source.trim();
    if (trimmed.length === 0) {
      return [];
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      try {
        const content = await this.httpClient.getText(trimmed);
        return this.parse(content);
      } catch (error) {
        throw new Error(`Subtitle fetch failed: ${errorMessage(error)}`);
      }
    }
    return this.parse(trimmed);
  }

  /** Auto-detect format and parse. */
  parse(content: string): SubtitleCue[] {
    const trimmed = content.trim();
    if (trimmed.startsWith('WEBVTT')) {
      return this.parseVtt(trimmed);
    }
    return this.parseSrt(trimmed);
  }

  /**
   * Parses SRT format:
   * ```
   * 1
   * 00:00:01,000 --> 00:00:04,000
   * Subtitle text
   *
   * 2
   * 00:00:05,000 --> 00:00:08,000
   * Next subtitle
   * ```
   */
  parseSrt(content: string): SubtitleCue[] {
    const cues: SubtitleCue[] = [];
    const blocks = content.replace(/\r\n/g, '\n').split(/\n\s*\n/);
    for (const block of blocks) {
      const lines = block.trim().split('\n');
      if (lines.length < 2) {
        continue;
      }
      const timeLineIdx = lines[0].includes('-->') ? 0 : 1;
      if (timeLineIdx >= lines.length || !lines[timeLineIdx].includes('-->')) {
        continue;
      }
      const times = this.parseTimeLine(lines[timeLineIdx], ',');
      if (times === undefined) {
        continue;
      }
      const text = lines.slice(timeLineIdx + 1).join('\n').trim();
      if (text.length > 0) {
        cues.push({ startMs: times[0], endMs: times[1], text });
      }
    }
    return cues;
  }

  /**
   * Parses WebVTT format:
   * ```
   * WEBVTT
   *
   * 00:00:01.000 --> 00:00:04.000
   * Subtitle text
   *
   * NOTE This is a comment
   *
   * 00:00:05.000 --> 00:00:08.000
   * Next subtitle
   * ```
   */
  parseVtt(content: string): SubtitleCue[] {
    const cues: SubtitleCue[] = [];
    const blocks = content.replace(/\r\n/g, '\n').split(/\n\s*\n/);
    for (const block of blocks) {
      const trimmed = block.trim();
      if (trimmed.startsWith('WEBVTT') || trimmed.startsWith('NOTE') || trimmed.length === 0) {
        continue;
      }
      const lines = trimmed.split('\n');
      let timeLineIdx = 0;
      if (!lines[0].includes('-->')) {
        timeLineIdx = 1;
      }
      if (timeLineIdx >= lines.length || !lines[timeLineIdx].includes('-->')) {
        continue;
      }
      const times = this.parseTimeLine(lines[timeLineIdx], '.');
      if (times === undefined) {
        continue;
      }
      const text = lines.slice(timeLineIdx + 1).join('\n').trim();
      if (text.length > 0) {
        cues.push({ startMs: times[0], endMs: times[1], text });
      }
    }
    return cues;
  }

  /**
   * Parses a time line like `00:01:23,456 --> 00:01:25,789` (SRT, comma ms)
   * or `00:01:23.456 --> 00:01:25.789` (VTT, dot ms).
   * Also handles `HH:MM:SS.mmm` and `MM:SS.mmm` formats.
   */
  private parseTimeLine(line: string, msSeparator: string): [number, number] | undefined {
    const parts = line.split('-->');
    if (parts.length !== 2) {
      return undefined;
    }
    const start = this.parseTimestamp(parts[0].trim(), msSeparator);
    const end = this.parseTimestamp(parts[1].trim().split(/\s/)[0], msSeparator);
    if (start === undefined || end === undefined) {
      return undefined;
    }
    return [start, end];
  }

  private parseTimestamp(ts: string, msSeparator: string): number | undefined {
    const parts = ts.split(msSeparator);
    const timePart = parts[0];
    const msPart = parts.length > 1 ? parts[1] : '0';
    const timeSegments = timePart.split(':');
    let hours = 0;
    let minutes = 0;
    let seconds = 0;
    if (timeSegments.length === 3) {
      hours = Number(timeSegments[0]);
      minutes = Number(timeSegments[1]);
      seconds = Number(timeSegments[2]);
    } else if (timeSegments.length === 2) {
      minutes = Number(timeSegments[0]);
      seconds = Number(timeSegments[1]);
    } else {
      seconds = Number(timeSegments[0]);
    }
    const ms = Number(msPart);
    if (!Number.isFinite(hours) || !Number.isFinite(minutes) || !Number.isFinite(seconds) || !Number.isFinite(ms)) {
      return undefined;
    }
    return (hours * 3600 + minutes * 60 + seconds) * 1000 + ms;
  }
}

export const subtitleService = new SubtitleService();
