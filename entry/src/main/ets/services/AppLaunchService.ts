import bundleManager from '@ohos.bundle.bundleManager';
import launcherBundleManager from '@ohos.bundle.launcherBundleManager';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import { AppLaunchItem } from '../models/TvBoxModels';

export interface AppQueryResult {
  item?: AppLaunchItem;
  message: string;
}

function now(): number {
  return Date.now();
}

function firstText(value: string): string {
  const text = value.trim();
  return text.length > 0 ? text.substring(0, 1).toUpperCase() : 'A';
}

function normalizeBundleName(value: string): string {
  return value.trim();
}

function normalizeAbilityName(value: string): string {
  return value.trim();
}

export class AppLaunchService {
  createManualItem(name: string, bundleName: string, abilityName: string, moduleName: string = ''): AppLaunchItem {
    const normalizedBundle = normalizeBundleName(bundleName);
    const normalizedAbility = normalizeAbilityName(abilityName);
    const displayName = name.trim() || normalizedBundle;
    return {
      id: 0,
      name: displayName,
      bundleName: normalizedBundle,
      abilityName: normalizedAbility,
      moduleName: moduleName.trim(),
      iconText: firstText(displayName || normalizedBundle),
      systemApp: false,
      userAdded: true,
      updateTime: now()
    };
  }

  async queryBundle(bundleName: string, fallbackAbilityName: string = ''): Promise<AppQueryResult> {
    const normalizedBundle = normalizeBundleName(bundleName);
    if (normalizedBundle.length === 0) {
      return { message: 'Bundle Name 不能为空' };
    }

    const launcherResult = this.queryLauncherAbility(normalizedBundle);
    if (launcherResult.item !== undefined) {
      return launcherResult;
    }

    const flags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION |
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_HAP_MODULE |
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_ABILITY;
    try {
      const info = await bundleManager.getBundleInfo(normalizedBundle, flags);
      const appInfo = info.appInfo;
      const appName = appInfo.label || appInfo.name || normalizedBundle;
      let abilityName = normalizeAbilityName(fallbackAbilityName);
      let moduleName = '';
      for (const moduleInfo of info.hapModulesInfo) {
        if (abilityName.length === 0 && moduleInfo.mainElementName.length > 0) {
          abilityName = moduleInfo.mainElementName;
          moduleName = moduleInfo.name;
          break;
        }
        const ability = moduleInfo.abilitiesInfo.find((row) => row.name === abilityName);
        if (ability !== undefined) {
          moduleName = moduleInfo.name;
          break;
        }
      }
      if (abilityName.length === 0) {
        return {
          item: this.createManualItem(appName, normalizedBundle, '', moduleName),
          message: '已读取应用信息，但未发现可直接启动的 Ability，可手动填写 Ability Name'
        };
      }
      return {
        item: {
          id: 0,
          name: appName,
          bundleName: normalizedBundle,
          abilityName,
          moduleName,
          iconText: firstText(appName || normalizedBundle),
          systemApp: appInfo.systemApp,
          userAdded: true,
          updateTime: now()
        },
        message: '已读取应用信息'
      };
    } catch (error) {
      return {
        item: this.createManualItem(normalizedBundle, normalizedBundle, fallbackAbilityName),
        message: `无法枚举或读取该应用信息：${this.errorMessage(error)}。可保存后尝试按 Bundle/Ability 启动。`
      };
    }
  }

  private queryLauncherAbility(bundleName: string): AppQueryResult {
    try {
      const launcherInfos = launcherBundleManager.getLauncherAbilityInfoSync(bundleName, 100);
      if (launcherInfos.length === 0) {
        return { message: '' };
      }
      const first = launcherInfos[0];
      const appInfo = first.applicationInfo;
      const label = appInfo.label || appInfo.name || bundleName;
      const element = first.elementName;
      return {
        item: {
          id: 0,
          name: label,
          bundleName: element.bundleName,
          abilityName: element.abilityName,
          moduleName: element.moduleName || '',
          iconText: firstText(label || bundleName),
          systemApp: appInfo.systemApp,
          userAdded: true,
          updateTime: now()
        },
        message: '已通过 Launcher Ability 读取应用信息'
      };
    } catch (_error) {
      return { message: '' };
    }
  }

  async launch(context: common.UIAbilityContext, item: AppLaunchItem): Promise<string> {
    if (item.bundleName.length === 0) {
      return 'Bundle Name 为空，无法启动';
    }
    const want: Want = {
      bundleName: item.bundleName
    };
    if (item.abilityName.length > 0) {
      want.abilityName = item.abilityName;
    }
    if (item.moduleName.length > 0) {
      want.moduleName = item.moduleName;
    }
    try {
      await context.startAbility(want);
      return `已发起启动：${item.name}`;
    } catch (error) {
      return `启动失败：${this.errorMessage(error)}`;
    }
  }

  uninstallHint(item: AppLaunchItem): string {
    return `HarmonyOS Next 普通应用没有 Android ACTION_DELETE 等价公开接口，已从列表移除 ${item.name}；如需卸载请到系统设置处理。`;
  }

  private errorMessage(error: unknown): string {
    if (error instanceof Error) {
      return error.message;
    }
    const record = error as Record<string, unknown>;
    const code = record['code'];
    const message = record['message'];
    if (code !== undefined || message !== undefined) {
      return `${code === undefined ? '' : String(code)} ${message === undefined ? '' : String(message)}`.trim();
    }
    return String(error);
  }
}

export const appLaunchService = new AppLaunchService();
