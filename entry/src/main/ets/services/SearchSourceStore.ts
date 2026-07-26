import { HawkConfig } from '../constants/HawkConfig';
import { SourceBean } from '../models/TvBoxModels';
import { asRecord, JsonNode, parseJson, safeString } from '../utils/JsonUtil';
import { apiConfigService } from './ApiConfigService';
import { settingsStore } from './SettingsStore';

/**
 * Android `SearchHelper`: per-config-URL map of enabled search sources,
 * stored under `HawkConfig.SOURCES_FOR_SEARCH` as `{apiUrl: {siteKey: "1"}}`.
 * Sources absent from the map are treated as enabled the first time.
 */
export class SearchSourceStore {
  private async readAll(): Promise<Record<string, Record<string, JsonNode>>> {
    const raw = await settingsStore.get<string>(HawkConfig.SOURCES_FOR_SEARCH, '');
    if (raw.length === 0) {
      return {};
    }
    try {
      const root: Record<string, JsonNode> = asRecord(parseJson(raw));
      const result: Record<string, Record<string, JsonNode>> = {};
      for (const api of Object.keys(root)) {
        result[api] = asRecord(root[api]);
      }
      return result;
    } catch (_error) {
      return {};
    }
  }

  private async currentApi(): Promise<string> {
    return settingsStore.get<string>(HawkConfig.API_URL, '');
  }

  /** Returns the enabled site keys, defaulting to every searchable source. */
  async getCheckedKeys(): Promise<string[]> {
    const api = await this.currentApi();
    const searchable = this.searchableSources();
    if (api.length === 0) {
      return searchable.map((item: SourceBean) => item.key);
    }
    const all = await this.readAll();
    const forApi = all[api];
    if (forApi === undefined || Object.keys(forApi).length === 0) {
      return searchable.map((item: SourceBean) => item.key);
    }
    const enabled: string[] = [];
    for (const source of searchable) {
      if (safeString(forApi, source.key) === '1') {
        enabled.push(source.key);
      }
    }
    return enabled;
  }

  async setCheckedKeys(keys: string[]): Promise<void> {
    const api = await this.currentApi();
    if (api.length === 0) {
      return;
    }
    const all = await this.readAll();
    const next: Record<string, string> = {};
    for (const key of keys) {
      next[key] = '1';
    }
    const merged: Record<string, Record<string, JsonNode>> = {};
    for (const existingApi of Object.keys(all)) {
      if (existingApi !== api) {
        merged[existingApi] = all[existingApi];
      }
    }
    merged[api] = next;
    await settingsStore.put(HawkConfig.SOURCES_FOR_SEARCH, JSON.stringify(merged));
  }

  searchableSources(): SourceBean[] {
    const state = apiConfigService.state;
    return Object.keys(state.sourceBeanList)
      .map((key: string) => state.sourceBeanList[key])
      .filter((source: SourceBean) => source.hide === 0 && source.searchable !== 0 && source.api.length > 0);
  }
}

export const searchSourceStore = new SearchSourceStore();
