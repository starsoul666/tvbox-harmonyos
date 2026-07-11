import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { AppLaunchItem } from '../models/TvBoxModels';
import { appDataStore } from '../services/AppDataStore';
import { AppQueryResult, appLaunchService } from '../services/AppLaunchService';
import { settingsStore } from '../services/SettingsStore';

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
  @State statusText: string = 'HarmonyOS 普通应用无法像 Android 一样直接枚举全部非系统应用，可添加 Bundle/Ability 后启动。';

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
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
    this.statusText = `正在编辑：${item.name}`;
  }

  saveManual(): void {
    const item = appLaunchService.createManualItem(this.appName, this.bundleName, this.abilityName, this.moduleName);
    if (item.bundleName.length === 0) {
      this.statusText = 'Bundle Name 不能为空';
      return;
    }
    item.id = this.editingId;
    const saved = appDataStore.save(item);
    this.statusText = `已保存：${saved.name}`;
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
    this.statusText = `${result.message}，已保存：${saved.name}`;
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

  @Builder
  appCard(item: AppLaunchItem) {
    Column() {
      Row() {
        Text(item.iconText)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .width(54)
          .height(54)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.deleteMode ? '#991b1b' : '#2563eb')
          .borderRadius(16)
        Column() {
          Text(item.name)
            .fontSize(20)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
          Text(item.bundleName)
            .fontSize(13)
            .fontColor('#93a4b8')
            .margin({ top: 4 })
            .maxLines(1)
          Text(item.abilityName.length > 0 ? item.abilityName : '未指定 Ability，启动时由系统解析')
            .fontSize(12)
            .fontColor('#64748b')
            .margin({ top: 4 })
            .maxLines(1)
        }.layoutWeight(1).margin({ left: 14 }).alignItems(HorizontalAlign.Start)
        if (this.deleteMode) {
          Text('移除')
            .fontSize(14)
            .fontColor('#fecaca')
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor('#7f1d1d')
            .borderRadius(10)
        } else {
          Button('编辑')
            .height(36)
            .fontSize(14)
            .onClick(() => {
              this.editApp(item);
            })
        }
      }.width('100%').alignItems(VerticalAlign.Center)
      if (item.systemApp) {
        Text('系统应用')
          .fontSize(12)
          .fontColor('#fbbf24')
          .alignSelf(ItemAlign.Start)
          .margin({ top: 10 })
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor('#111827')
    .borderRadius(16)
    .border({ width: 1, color: this.deleteMode ? '#ef4444' : '#1f2937' })
    .onClick(() => this.onAppClicked(item))
  }

  build() {
    Column() {
      Row() {
        Text('< 返回')
          .fontSize(18)
          .fontColor(Color.White)
          .onClick(() => router.back())
        Blank()
        Button(this.deleteMode ? '退出删除模式' : '删除模式')
          .height(40)
          .backgroundColor(this.deleteMode ? '#7f1d1d' : '#374151')
          .onClick(() => this.deleteMode = !this.deleteMode)
      }.width('100%').alignItems(VerticalAlign.Center)

      Text('应用')
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .alignSelf(ItemAlign.Start)
        .margin({ top: 28 })

      Text(this.statusText)
        .fontSize(15)
        .fontColor('#d1d5db')
        .alignSelf(ItemAlign.Start)
        .margin({ top: 12 })

      Row() {
        Column() {
          Text(this.editingId > 0 ? '编辑启动项' : '添加启动项')
            .fontSize(20)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
          TextInput({ text: this.appName, placeholder: '名称，可留空' })
            .height(48)
            .fontSize(16)
            .margin({ top: 14 })
            .onChange((value: string) => this.appName = value)
          TextInput({ text: this.bundleName, placeholder: 'Bundle Name，例如 com.example.app' })
            .height(48)
            .fontSize(16)
            .margin({ top: 12 })
            .onChange((value: string) => this.bundleName = value)
          TextInput({ text: this.abilityName, placeholder: 'Ability Name，可先留空再解析' })
            .height(48)
            .fontSize(16)
            .margin({ top: 12 })
            .onChange((value: string) => this.abilityName = value)
          TextInput({ text: this.moduleName, placeholder: 'Module Name，可选' })
            .height(48)
            .fontSize(16)
            .margin({ top: 12 })
            .onChange((value: string) => this.moduleName = value)
          Row() {
            Button('解析并保存')
              .height(42)
              .onClick(() => this.queryAndSave())
            Button('直接保存')
              .height(42)
              .margin({ left: 12 })
              .backgroundColor('#374151')
              .onClick(() => this.saveManual())
            Button('清空')
              .height(42)
              .margin({ left: 12 })
              .backgroundColor('#1f2937')
              .onClick(() => this.resetForm())
          }.width('100%').margin({ top: 14 })
          Text('删除模式在 HarmonyOS 版本中移除保存的启动项；系统卸载入口受平台权限限制，无法复刻 Android ACTION_DELETE。')
            .fontSize(13)
            .fontColor('#93a4b8')
            .margin({ top: 14 })
            .alignSelf(ItemAlign.Start)
        }
        .width(420)
        .padding(18)
        .backgroundColor('#0f172a')
        .borderRadius(16)

        Column() {
          Row() {
            Text(`已保存应用：${this.apps.length}`)
              .fontSize(20)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Medium)
            Blank()
            Button('刷新')
              .height(36)
              .backgroundColor('#374151')
              .onClick(() => this.refreshApps())
          }.width('100%').alignItems(VerticalAlign.Center)

          if (this.apps.length === 0) {
            Column() {
              Text('暂无应用启动项')
                .fontSize(18)
                .fontColor('#d1d5db')
              Text('先在左侧输入 Bundle Name 和 Ability Name。')
                .fontSize(14)
                .fontColor('#93a4b8')
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
    .backgroundColor('#0b1020')
  }
}
