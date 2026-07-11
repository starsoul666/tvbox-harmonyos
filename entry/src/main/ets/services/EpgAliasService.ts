import resourceManager from '@ohos.resourceManager';
import util from '@ohos.util';
import { asArray, asRecord, safeString } from '../utils/JsonUtil';

export interface EpgAliasInfo {
  logo: string;
  epgId: string;
}

export class EpgAliasService {
  private aliasMap: Record<string, EpgAliasInfo> = {};
  private loaded: boolean = false;

  async init(manager: resourceManager.ResourceManager): Promise<void> {
    if (this.loaded) {
      return;
    }
    try {
      const bytes = await manager.getRawFileContent('epg_data.json');
      const text = util.TextDecoder.create('utf-8').decode(bytes);
      const root = asRecord(JSON.parse(text) as unknown);
      const rows = asArray(root['epgs']);
      for (const row of rows) {
        const obj = asRecord(row);
        const logo = safeString(obj, 'logo').trim();
        const epgId = safeString(obj, 'epgid').trim();
        const names = safeString(obj, 'name').split(',');
        for (const rawName of names) {
          const name = rawName.trim();
          if (name.length > 0 && epgId.length > 0) {
            this.aliasMap[name] = { logo, epgId };
          }
        }
      }
    } catch (_error) {
      this.aliasMap = {};
    } finally {
      this.loaded = true;
    }
  }

  getEpgInfo(channelName: string): EpgAliasInfo | undefined {
    return this.aliasMap[channelName];
  }
}

export const epgAliasService = new EpgAliasService();
