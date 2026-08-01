import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { AppLaunchItem } from '../models/TvBoxModels';
import { appDataStore } from '../services/AppDataStore';
import { AppQueryResult, appLaunchService } from '../services/AppLaunchService';
import { appearanceService, AppsLabels, ThemePalette } from '../services/AppearanceService';
import { settingsStore } from '../services/SettingsStore';
import { HawkConfig } from '../constants/HawkConfig';

@Entry
@Component
struct Apps {
  @State apps: AppLaunchItem[] = [];
  @State deleteMode: boolean = false;
  @State editingId: number = 0;
  @State appName: string = '';
  @State bundleName: string = '';
  @State abilityName: string = '';
  @State moduleName: string = '';
  @State statusText: string = '';
  @State themeSelect: number = 0;

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    await appearanceService.init();
    this.themeSelect = await settingsStore.get<number>(HawkConfig.THEME_SELECT, 0);
    this.statusText = this.labels().initialStatus;
    this.refreshApps();
  }

  refreshApps(): void {
    this.apps = appDataStore.getAll();
  }

  resetForm(): void {
    this.editingId = 0;
    this.appName = '';
    this.bundleName = '';
    this.abilityName = '';
    this.moduleName = '';
  }

  editApp(item: AppLaunchItem): void {
    this.deleteMode = false;
    this.editingId = item.id;
    this.appName = item.name;
    this.bundleName = item.bundleName;
    this.abilityName = item.abilityName;
    this.moduleName = item.moduleName;
    this.statusText = `${this.labels().editingPrefix}${item.name}`;
  }

  saveManual(): void {
    const item = appLaunchService.createManualItem(this.appName, this.bundleName, this.abilityName, this.moduleName);
    if (item.bundleName.length === 0) {
      this.statusText = this.labels().bundleEmpty;
      return;
    }
    item.id = this.editingId;
    const saved = appDataStore.save(item);
    this.statusText = `${this.labels().savedPrefix}${saved.name}`;
    this.resetForm();
    this.refreshApps();
  }

  async queryAndSave(): Promise<void> {
    const result: AppQueryResult = await appLaunchService.queryBundle(this.bundleName, this.abilityName);
    this.statusText = result.message;
    if (result.item === undefined) {
      return;
    }
    result.item.id = this.editingId;
    if (this.appName.trim().length > 0) {
      result.item.name = this.appName.trim();
      result.item.iconText = result.item.name.substring(0, 1).toUpperCase();
    }
    if (this.moduleName.trim().length > 0) {
      result.item.moduleName = this.moduleName.trim();
    }
    const saved = appDataStore.save(result.item);
    this.statusText = `${result.message}${this.labels().querySavedPrefix}${saved.name}`;
    this.resetForm();
    this.refreshApps();
  }

  removeApp(item: AppLaunchItem): void {
    appDataStore.delete(item.id);
    this.refreshApps();
    this.statusText = appLaunchService.uninstallHint(item);
  }

  async launchApp(item: AppLaunchItem): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;
    this.statusText = await appLaunchService.launch(context, item);
  }

  async onAppClicked(item: AppLaunchItem): Promise<void> {
    if (this.deleteMode) {
      this.removeApp(item);
      return;
    }
    await this.launchApp(item);
  }

  theme(): ThemePalette {
    return appearanceService.themeByIndex(this.themeSelect);
  }

  labels(): AppsLabels {
    return appearanceService.appsLabels();
  }

  @Builder
  appCard(item: AppLaunchItem) {
    Column() {
      Row() {
        Text(item.iconText)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme().text)
          .width(54)
          .height(54)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.deleteMode ? '#991b1b' : this.theme().primary)
          .borderRadius(16)
        Column() {
          Text(item.name)
            .fontSize(20)
            .fontColor(this.theme().text)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
          Text(item.bundleName)
            .fontSize(13)
            .fontColor(this.theme().mutedText)
            .margin({ top: 4 })
            .maxLines(1)
          Text(item.abilityName.length > 0 ? item.abilityName : this.labels().abilityMissing)
            .fontSize(12)
            .fontColor(this.theme().subtleText)
            .margin({ top: 4 })
            .maxLines(1)
        }.layoutWeight(1).margin({ left: 14 }).alignItems(HorizontalAlign.Start)
        if (this.deleteMode) {
          Text(this.labels().remove)
            .fontSize(14)
            .fontColor('#fecaca')
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor('#7f1d1d')
            .borderRadius(10)
        } else {
          Button(this.labels().edit)
            .height(36)
            .fontSize(14)
            .onClick(() => {
              this.editApp(item);
            })
        }
      }.width('100%').alignItems(VerticalAlign.Center)
      if (item.systemApp) {
        Text(this.labels().systemApp)
          .fontSize(12)
          .fontColor('#fbbf24')
          .alignSelf(ItemAlign.Start)
          .margin({ top: 10 })
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.theme().fieldBg)
    .borderRadius(16)
    .border({ width: 1, color: this.deleteMode ? '#ef4444' : this.theme().panelBg })
    .onClick(() => this.onAppClicked(item))
  }

  build() {
    Column() {
      Row() {
        Text(this.labels().back)
          .fontSize(18)
          .fontColor(this.theme().text)
          .onClick(() => router.back())
        Blank()
        Button(this.deleteMode ? this.labels().exitDeleteMode : this.labels().deleteMode)
          .height(40)
          .backgroundColor(this.deleteMode ? '#7f1d1d' : '#374151')
          .onClick(() => this.deleteMode = !this.deleteMode)
      }.width('100%').alignItems(VerticalAlign.Center)

      Text(this.labels().title)
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.theme().text)
        .alignSelf(ItemAlign.Start)
        .margin({ top: 28 })

      Text(this.statusText)
        .fontSize(15)
        .fontColor(this.theme().text)
        .alignSelf(ItemAlign.Start)
        .margin({ top: 12 })

      Row() {
        Column() {
          Text(this.editingId > 0 ? this.labels().editEntry : this.labels().addEntry)
            .fontSize(20)
            .fontColor(this.theme().text)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
          TextInput({ text: this.appName, placeholder: this.labels().namePlaceholder })
            .height(48)
            .fontSize(16)
            .margin({ top: 14 })
            .onChange((value: string) => this.appName = value)
          TextInput({ text: this.bundleName, placeholder: this.labels().bundlePlaceholder })
            .height(48)
            .fontSize(16)
            .margin({ top: 12 })
            .onChange((value: string) => this.bundleName = value)
          TextInput({ text: this.abilityName, placeholder: this.labels().abilityPlaceholder })
            .height(48)
            .fontSize(16)
            .margin({ top: 12 })
            .onChange((value: string) => this.abilityName = value)
          TextInput({ text: this.moduleName, placeholder: this.labels().modulePlaceholder })
            .height(48)
            .fontSize(16)
            .margin({ top: 12 })
            .onChange((value: string) => this.moduleName = value)
          Row() {
            Button(this.labels().resolveAndSave)
              .height(42)
              .onClick(() => this.queryAndSave())
            Button(this.labels().saveDirect)
              .height(42)
              .margin({ left: 12 })
              .backgroundColor(this.theme().cardActiveBg)
              .onClick(() => this.saveManual())
            Button(this.labels().clear)
              .height(42)
              .margin({ left: 12 })
              .backgroundColor(this.theme().panelBg)
              .onClick(() => this.resetForm())
          }.width('100%').margin({ top: 14 })
          Text(this.labels().deleteNotice)
            .fontSize(13)
            .fontColor(this.theme().mutedText)
            .margin({ top: 14 })
            .alignSelf(ItemAlign.Start)
        }
        .width(420)
        .padding(18)
        .backgroundColor(this.theme().cardBg)
        .borderRadius(16)

        Column() {
          Row() {
            Text(`${this.labels().savedCountPrefix}${this.apps.length}`)
              .fontSize(20)
              .fontColor(this.theme().text)
              .fontWeight(FontWeight.Medium)
            Blank()
            Button(this.labels().refresh)
              .height(36)
              .backgroundColor(this.theme().cardActiveBg)
              .onClick(() => this.refreshApps())
          }.width('100%').alignItems(VerticalAlign.Center)

          if (this.apps.length === 0) {
            Column() {
              Text(this.labels().empty)
                .fontSize(18)
                .fontColor(this.theme().mutedText)
              Text(this.labels().emptyHint)
                .fontSize(14)
                .fontColor(this.theme().mutedText)
                .margin({ top: 8 })
            }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
          } else {
            List() {
              ForEach(this.apps, (item: AppLaunchItem) => {
                ListItem() {
                  this.appCard(item)
                }.margin({ top: 12 })
              }, (item: AppLaunchItem) => `${item.id}`)
            }.width('100%').layoutWeight(1).margin({ top: 8 })
          }
        }
        .layoutWeight(1)
        .height('100%')
        .margin({ left: 24 })
      }
      .width('100%')
      .layoutWeight(1)
      .margin({ top: 22 })
    }
    .width('100%')
    .height('100%')
    .padding(48)
    .backgroundColor(this.theme().pageBg)
  }
}
