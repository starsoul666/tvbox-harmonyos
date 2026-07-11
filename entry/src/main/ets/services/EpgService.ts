import { asArray, asRecord, safeString } from '../utils/JsonUtil';
import { HttpClient } from './HttpClient';

export interface EpgProgram {
  title: string;
  start: string;
  end: string;
  index: number;
  isCurrent: boolean;
  isFuture: boolean;
  playSeekStart: string;
  playSeekEnd: string;
}

export interface EpgLoadResult {
  dateText: string;
  requestUrl: string;
  programs: EpgProgram[];
}

export class EpgService {
  readonly defaultEpgUrl: string = 'https://epg.112114.xyz/';
  private readonly httpClient: HttpClient = new HttpClient();

  async loadPrograms(epgAddress: string, channelName: string, dateOffset: number = 0): Promise<EpgLoadResult> {
    const dateText = this.formatDate(this.offsetDate(dateOffset));
    const requestUrl = this.buildEpgUrl(epgAddress, channelName, dateText);
    const text = await this.httpClient.getText(requestUrl);
    const root = asRecord(JSON.parse(text) as unknown);
    const rows = asArray(root['epg_data']);
    const programs: EpgProgram[] = [];
    const currentMinutes = dateOffset === 0 ? this.currentMinutes() : -1;
    const nowTime = Date.now();
    for (let i = 0; i < rows.length; i++) {
      const row = asRecord(rows[i]);
      const title = safeString(row, 'title', '未知节目').trim();
      const start = safeString(row, 'start').trim();
      const end = safeString(row, 'end').trim();
      if (start.length === 0 && end.length === 0 && title.length === 0) {
        continue;
      }
      const startTime = this.programTimeMillis(dateText, start, 0);
      programs.push({
        title,
        start,
        end,
        index: programs.length,
        isCurrent: currentMinutes >= 0 && this.isCurrentProgram(start, end, currentMinutes),
        isFuture: startTime > 0 && nowTime < startTime,
        playSeekStart: this.playSeekTime(dateText, start),
        playSeekEnd: this.playSeekTime(dateText, end)
      });
    }
    return { dateText, requestUrl, programs };
  }

  buildEpgUrl(epgAddress: string, channelName: string, dateText: string): string {
    const address = epgAddress.trim().length === 0 ? this.defaultEpgUrl : epgAddress.trim();
    const encodedName = encodeURIComponent(channelName);
    if (address.includes('{name}') && address.includes('{date}')) {
      return address.split('{name}').join(encodedName).split('{date}').join(dateText);
    }
    return `${address}?ch=${encodedName}&date=${dateText}`;
  }

  private offsetDate(offset: number): Date {
    const date = new Date();
    date.setDate(date.getDate() + offset);
    return date;
  }

  private formatDate(date: Date): string {
    return `${date.getFullYear()}-${this.twoDigits(date.getMonth() + 1)}-${this.twoDigits(date.getDate())}`;
  }

  private twoDigits(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }

  private currentMinutes(): number {
    const now = new Date();
    return now.getHours() * 60 + now.getMinutes();
  }

  private isCurrentProgram(start: string, end: string, currentMinutes: number): boolean {
    const startMinutes = this.timeToMinutes(start);
    const rawEndMinutes = this.timeToMinutes(end);
    if (startMinutes < 0 || rawEndMinutes < 0) {
      return false;
    }
    const endMinutes = rawEndMinutes < startMinutes ? rawEndMinutes + 24 * 60 : rawEndMinutes;
    const compareMinutes = currentMinutes < startMinutes && endMinutes > 24 * 60
      ? currentMinutes + 24 * 60
      : currentMinutes;
    return compareMinutes >= startMinutes && compareMinutes <= endMinutes;
  }

  private timeToMinutes(value: string): number {
    const parts = value.split(':');
    if (parts.length < 2) {
      return -1;
    }
    const hour = Number(parts[0]);
    const minute = Number(parts[1]);
    if (Number.isNaN(hour) || Number.isNaN(minute)) {
      return -1;
    }
    return hour * 60 + minute;
  }

  private programTimeMillis(dateText: string, timeText: string, dayOffset: number): number {
    const dateParts = dateText.split('-');
    const timeParts = timeText.split(':');
    if (dateParts.length < 3 || timeParts.length < 2) {
      return -1;
    }
    const year = Number(dateParts[0]);
    const month = Number(dateParts[1]);
    const day = Number(dateParts[2]);
    const hour = Number(timeParts[0]);
    const minute = Number(timeParts[1]);
    if (Number.isNaN(year) || Number.isNaN(month) || Number.isNaN(day) ||
      Number.isNaN(hour) || Number.isNaN(minute)) {
      return -1;
    }
    const date = new Date(year, month - 1, day + dayOffset, hour, minute, 0, 0);
    return date.getTime();
  }

  private playSeekTime(dateText: string, timeText: string): string {
    const dateParts = dateText.split('-');
    const timeParts = timeText.split(':');
    if (dateParts.length < 3 || timeParts.length < 2) {
      return '';
    }
    const year = Number(dateParts[0]);
    const month = Number(dateParts[1]);
    const day = Number(dateParts[2]);
    const hour = Number(timeParts[0]);
    const minute = Number(timeParts[1]);
    if (Number.isNaN(year) || Number.isNaN(month) || Number.isNaN(day) ||
      Number.isNaN(hour) || Number.isNaN(minute)) {
      return '';
    }
    return `${year}${this.twoDigits(month)}${this.twoDigits(day)}${this.twoDigits(hour)}${this.twoDigits(minute)}30`;
  }
}

export const epgService = new EpgService();
