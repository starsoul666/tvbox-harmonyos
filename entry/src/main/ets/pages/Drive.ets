import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { HawkConfig } from '../constants/HawkConfig';
import { DriveFileItem, DriveType, StorageDrive, VodInfo } from '../models/TvBoxModels';
import { PlayerConfig } from '../domain/playback/PlayerConfig';
import { appearanceService, DriveLabels, ThemePalette } from '../services/AppearanceService';
import { driveDataStore } from '../services/DriveDataStore';
import { driveService } from '../services/DriveService';
import { settingsStore } from '../services/SettingsStore';
import { vodDataStore } from '../services/VodDataStore';
import { errorMessage } from '../utils/ErrorUtil';

@Entry
@Component
struct Drive {
  @State drives: StorageDrive[] = [];
  @State items: DriveFileItem[] = [];
  @State allItems: DriveFileItem[] = [];
  @State selectedDrive: StorageDrive | null = null;
  @State currentPath: string = '/';
  @State driveTypeInput: number = DriveType.ALISTWEB;
  @State nameInput: string = '';
  @State urlInput: string = '';
  @State usernameInput: string = '';
  @State passwordInput: string = '';
  @State initPathInput: string = '/';
  @State editDriveId: number = 0;
  @State statusText: string = '';
  @State loading: boolean = false;
  @State sortType: number = 0;
  @State searchKeyword: string = '';
  @State themeSelect: number = 0;

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    await appearanceService.init();
    this.themeSelect = await settingsStore.get<number>(HawkConfig.THEME_SELECT, 0);
    this.sortType = await settingsStore.get<number>(HawkConfig.STORAGE_DRIVE_SORT, 0);
    this.statusText = this.labels().initialStatus;
    this.refreshDrives();
  }

  refreshDrives(): void {
    this.drives = driveDataStore.getAll();
  }

  async saveDrive(): Promise<void> {
    const name = this.nameInput.trim();
    const url = this.urlInput.trim();
    if (name.length === 0 || (this.driveTypeInput !== DriveType.LOCAL && url.length === 0)) {
      this.statusText = this.driveTypeInput === DriveType.LOCAL ? this.labels().needLocalPath : this.labels().needNameAndUrl;
      promptAction.showToast({ message: this.statusText });
      return;
    }
    const initPath = this.initPathInput.trim().length === 0 ? '/' : this.initPathInput.trim();
    let configJson = '';
    if (this.driveTypeInput === DriveType.LOCAL) {
      configJson = JSON.stringify({ rootPath: name });
    } else if (this.driveTypeInput === DriveType.WEBDAV) {
      configJson = JSON.stringify({
        url,
        username: this.usernameInput,
        password: this.passwordInput,
        initPath
      });
    } else {
      configJson = JSON.stringify({
        url,
        password: this.passwordInput,
        initPath
      });
    }
    const saved = driveDataStore.save({
      id: this.editDriveId,
      name,
      type: this.driveTypeInput,
      configJson
    });
    this.clearEditorFields();
    this.refreshDrives();
    await this.openDrive(saved);
  }

  editDrive(drive: StorageDrive): void {
    if (drive.type !== DriveType.LOCAL && drive.type !== DriveType.ALISTWEB && drive.type !== DriveType.WEBDAV) {
      this.statusText = this.labels().editUnsupported;
      return;
    }
    this.editDriveId = drive.id;
    this.driveTypeInput = drive.type;
    this.nameInput = drive.name;
    if (drive.type === DriveType.LOCAL) {
      const config = driveService.parseLocalConfig(drive);
      this.nameInput = config.rootPath;
      this.urlInput = '';
      this.usernameInput = '';
      this.passwordInput = '';
      this.initPathInput = '/';
    } else if (drive.type === DriveType.WEBDAV) {
      const config = driveService.parseWebDavConfig(drive);
      this.urlInput = config.url;
      this.usernameInput = config.username;
      this.passwordInput = config.password;
      this.initPathInput = config.initPath;
    } else {
      const config = driveService.parseAlistConfig(drive);
      this.urlInput = config.url;
      this.usernameInput = '';
      this.passwordInput = config.password;
      this.initPathInput = config.initPath;
    }
    this.statusText = `${this.labels().editingPrefix}${drive.name}`;
  }

  resetEditor(): void {
    this.clearEditorFields();
    this.statusText = this.labels().editorCleared;
  }

  clearEditorFields(): void {
    this.editDriveId = 0;
    this.driveTypeInput = DriveType.LOCAL;
    this.nameInput = '';
    this.urlInput = '';
    this.usernameInput = '';
    this.passwordInput = '';
    this.initPathInput = '/';
  }

  async openDrive(drive: StorageDrive): Promise<void> {
    this.selectedDrive = drive;
    this.searchKeyword = '';
    if (drive.type !== DriveType.LOCAL && drive.type !== DriveType.ALISTWEB && drive.type !== DriveType.WEBDAV) {
      this.items = [];
      this.allItems = [];
      this.statusText = this.labels().unknownType;
      return;
    }
    if (drive.type === DriveType.LOCAL) {
      this.currentPath = driveService.parseLocalConfig(drive).rootPath;
    } else if (drive.type === DriveType.WEBDAV) {
      this.currentPath = driveService.parseWebDavConfig(drive).initPath;
    } else {
      this.currentPath = driveService.parseAlistConfig(drive).initPath;
    }
    await this.loadCurrentPath();
  }

  async loadCurrentPath(): Promise<void> {
    if (this.selectedDrive === null) {
      return;
    }
    if (this.selectedDrive.type !== DriveType.LOCAL && this.selectedDrive.type !== DriveType.ALISTWEB && this.selectedDrive.type !== DriveType.WEBDAV) {
      this.statusText = this.labels().unknownType;
      return;
    }
    this.loading = true;
    this.statusText = `${this.labels().loadingPathPrefix}${this.currentPath}`;
    try {
      let list: DriveFileItem[] = [];
      if (this.selectedDrive.type === DriveType.LOCAL) {
        list = await driveService.listLocal(this.selectedDrive, this.currentPath);
      } else if (this.selectedDrive.type === DriveType.WEBDAV) {
        list = await driveService.listWebDav(this.selectedDrive, this.currentPath);
      } else {
        list = await driveService.listAlist(this.selectedDrive, this.currentPath);
      }
      this.allItems = driveService.sortItems(list, this.sortType);
      this.applySearchFilter();
      this.statusText = `${this.labels().loadedCountPrefix}${this.allItems.length}${this.labels().loadedCountMiddle}${this.currentPath}`;
    } catch (error) {
      this.items = [];
      this.allItems = [];
      this.statusText = `${this.labels().loadFailedPrefix}${errorMessage(error)}`;
    } finally {
      this.loading = false;
    }
  }

  async changeSortType(): Promise<void> {
    this.sortType = this.sortType >= 3 ? 0 : this.sortType + 1;
    await settingsStore.put(HawkConfig.STORAGE_DRIVE_SORT, this.sortType);
    this.allItems = driveService.sortItems(this.allItems, this.sortType);
    this.applySearchFilter();
  }

  applySearchFilter(): void {
    const keyword = this.searchKeyword.trim().toLowerCase();
    if (keyword.length === 0) {
      this.items = this.allItems;
      if (this.selectedDrive !== null) {
        this.statusText = `${this.labels().loadedCountPrefix}${this.allItems.length}${this.labels().loadedCountMiddle}${this.currentPath}`;
      }
      return;
    }
    this.items = this.allItems.filter((item: DriveFileItem) => item.name.toLowerCase().includes(keyword));
    this.statusText = `${this.labels().searchResultPrefix}${this.searchKeyword.trim()}${this.labels().searchResultMiddle}${this.items.length}/${this.allItems.length}${this.labels().searchResultSuffix}`;
  }

  updateSearchKeyword(value: string): void {
    this.searchKeyword = value;
    this.applySearchFilter();
  }

  clearSearchKeyword(): void {
    this.searchKeyword = '';
    this.applySearchFilter();
  }

  async openItem(item: DriveFileItem): Promise<void> {
    if (this.selectedDrive === null) {
      return;
    }
    if (!item.isFile) {
      this.currentPath = item.path;
      await this.loadCurrentPath();
      return;
    }
    if (!driveService.isVideoFile(item)) {
      this.statusText = `${this.labels().nonVideoPrefix}${item.name}`;
      return;
    }
    let fileUrl = '';
    if (this.selectedDrive.type === DriveType.LOCAL) {
      fileUrl = driveService.resolveLocalFileUrl(item.path);
    } else if (this.selectedDrive.type === DriveType.WEBDAV) {
      fileUrl = driveService.resolveWebDavFileUrl(this.selectedDrive, item);
    } else {
      fileUrl = driveService.resolveAlistFileUrl(this.selectedDrive, item);
    }
    const vod: VodInfo = {
      id: fileUrl,
      name: item.name,
      seriesFlags: [{ name: 'drive' }],
      seriesMap: {
        drive: [{ name: item.name, url: fileUrl }]
      },
      playFlag: 'drive',
      playIndex: 0,
      playGroup: 0,
      playGroupCount: 1,
      playNote: item.name,
      rawUrl: fileUrl,
      last: fileUrl,
      sourceKey: '_drive'
    };
    const authorization = this.selectedDrive.type === DriveType.WEBDAV
      ? driveService.getWebDavAuthorization(this.selectedDrive)
      : '';
    if (authorization.length > 0) {
      // AVPlayer receives these headers through PlaybackSession, so WebDAV Basic auth works.
      const config = new PlayerConfig();
      config.headers = { 'Authorization': authorization };
      vod.playerCfg = config.stringify();
    }
    vodDataStore.insertVodRecord('_drive', vod);
    router.pushUrl({
      url: 'pages/Play',
      params: {
        sourceKey: '_drive',
        vodId: fileUrl,
        playFlag: 'drive',
        playIndex: '0',
        playUrl: fileUrl,
        rawUrl: fileUrl,
        episodeName: item.name,
        playerCfg: vod.playerCfg || '',
        episodesJson: JSON.stringify(vod.seriesMap['drive'])
      }
    });
  }

  async goUp(): Promise<void> {
    if (this.selectedDrive === null) {
      return;
    }
    const parent = this.selectedDrive.type === DriveType.LOCAL
      ? driveService.parentLocalPath(this.currentPath, driveService.parseLocalConfig(this.selectedDrive).rootPath)
      : driveService.parentPath(this.currentPath);
    if (parent === this.currentPath) {
      this.selectedDrive = null;
      this.items = [];
      this.allItems = [];
      this.searchKeyword = '';
      this.statusText = this.labels().backToList;
      return;
    }
    this.currentPath = parent;
    await this.loadCurrentPath();
  }

  deleteDrive(drive: StorageDrive): void {
    driveDataStore.delete(drive.id);
    if (this.selectedDrive !== null && this.selectedDrive.id === drive.id) {
      this.selectedDrive = null;
      this.items = [];
      this.allItems = [];
      this.searchKeyword = '';
      this.statusText = this.labels().deletedCurrent;
    }
    if (this.editDriveId === drive.id) {
      this.resetEditor();
    }
    this.refreshDrives();
  }

  sortName(): string {
    const l = this.labels();
    switch (this.sortType) {
      case 1:
        return this.labels().sortNameDesc;
      case 2:
        return this.labels().sortTimeAsc;
      case 3:
        return this.labels().sortTimeDesc;
      default:
        return this.labels().sortNameAsc;
    }
  }

  browserTitle(): string {
    if (this.selectedDrive === null) {
      return this.labels().listTitle;
    }
    return `${this.selectedDrive.name}  ${this.currentPath}`;
  }

  driveTypeName(type: number): string {
    const l = this.labels();
    if (type === DriveType.LOCAL) {
      return l.driveTypeLocal;
    }
    if (type === DriveType.WEBDAV) {
      return l.driveTypeWebDav;
    }
    if (type === DriveType.ALISTWEB) {
      return l.driveTypeAlist;
    }
    return `${l.driveTypeUnknownPrefix}${type}`;
  }

  driveTypeInputName(): string {
    const l = this.labels();
    if (this.driveTypeInput === DriveType.LOCAL) {
      return l.driveTypeLocal;
    }
    return this.driveTypeInput === DriveType.WEBDAV ? l.driveTypeWebDav : this.labels().alist;
  }

  labels(): DriveLabels {
    return appearanceService.driveLabels();
  }

  theme(): ThemePalette {
    return appearanceService.themeByIndex(this.themeSelect);
  }


  build() {
    Column() {
      Row() {
        Text(this.labels().back)
          .fontSize(18)
          .fontColor(this.theme().text)
          .onClick(() => router.back())
        Text(this.labels().title)
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme().text)
          .margin({ left: 24 })
          .layoutWeight(1)
        Button(`${this.labels().sortPrefix}${this.sortName()}`)
          .height(40)
          .onClick(() => this.changeSortType())
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.statusText)
        .fontSize(14)
        .fontColor(this.theme().mutedText)
        .margin({ top: 12 })
        .width('100%')

      Row() {
        Column() {
          Text(`${this.editDriveId > 0 ? this.labels().editPrefix : this.labels().addPrefix}${this.driveTypeInputName()}`)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.theme().text)
          if (this.editDriveId > 0) {
            Text(`${this.labels().editRecordPrefix}${this.editDriveId}`)
              .fontSize(13)
              .fontColor(this.theme().mutedText)
              .margin({ top: 6 })
          }
          Row() {
            Button(this.labels().local)
              .height(36)
              .layoutWeight(1)
              .backgroundColor(this.driveTypeInput === DriveType.LOCAL ? this.theme().primary : this.theme().cardActiveBg)
              .onClick(() => this.driveTypeInput = DriveType.LOCAL)
            Button(this.labels().alist)
              .height(36)
              .layoutWeight(1)
              .margin({ left: 10 })
              .backgroundColor(this.driveTypeInput === DriveType.ALISTWEB ? this.theme().primary : this.theme().cardActiveBg)
              .onClick(() => this.driveTypeInput = DriveType.ALISTWEB)
            Button(this.labels().webDav)
              .height(36)
              .layoutWeight(1)
              .margin({ left: 10 })
              .backgroundColor(this.driveTypeInput === DriveType.WEBDAV ? this.theme().primary : this.theme().cardActiveBg)
              .onClick(() => this.driveTypeInput = DriveType.WEBDAV)
          }
          .margin({ top: 12 })
          TextInput({
            text: this.nameInput,
            placeholder: this.driveTypeInput === DriveType.LOCAL ? this.labels().namePlaceholderLocal : this.labels().namePlaceholder
          })
            .height(44)
            .fontSize(15)
            .margin({ top: 12 })
            .onChange((value: string) => this.nameInput = value)
          if (this.driveTypeInput !== DriveType.LOCAL) {
            TextInput({
              text: this.urlInput,
              placeholder: this.driveTypeInput === DriveType.WEBDAV
                ? this.labels().urlPlaceholderWebDav
                : this.labels().urlPlaceholderAlist
            })
              .height(44)
              .fontSize(15)
              .margin({ top: 10 })
              .onChange((value: string) => this.urlInput = value)
            if (this.driveTypeInput === DriveType.WEBDAV) {
              TextInput({ text: this.usernameInput, placeholder: this.labels().usernamePlaceholder })
                .height(44)
                .fontSize(15)
                .margin({ top: 10 })
                .onChange((value: string) => this.usernameInput = value)
            }
            TextInput({
              text: this.passwordInput,
              placeholder: this.driveTypeInput === DriveType.WEBDAV ? this.labels().passwordPlaceholderWebDav : this.labels().passwordPlaceholderAlist
            })
              .height(44)
              .fontSize(15)
              .margin({ top: 10 })
              .onChange((value: string) => this.passwordInput = value)
            TextInput({ text: this.initPathInput, placeholder: this.labels().initPathPlaceholder })
              .height(44)
              .fontSize(15)
              .margin({ top: 10 })
              .onChange((value: string) => this.initPathInput = value)
          } else {
            Text(this.labels().sandboxNotice)
              .fontSize(12)
              .fontColor(this.theme().mutedText)
              .margin({ top: 10 })
          }
          Row() {
            Button(this.editDriveId > 0 ? this.labels().saveEdit : this.labels().saveAndOpen)
              .height(42)
              .layoutWeight(1)
              .onClick(() => this.saveDrive())
            Button(this.labels().clear)
              .height(42)
              .margin({ left: 10 })
              .onClick(() => this.resetEditor())
          }
          .margin({ top: 12 })
        }
        .width(360)
        .padding(18)
        .backgroundColor(this.theme().fieldBg)
        .borderRadius(14)

        Column() {
          Row() {
            Text(this.browserTitle())
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.theme().text)
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            if (this.selectedDrive !== null) {
              Button(this.labels().parent)
                .height(38)
                .onClick(() => this.goUp())
            }
          }
          .width('100%')

          if (this.selectedDrive === null) {
            if (this.drives.length === 0) {
              Text(this.labels().emptyDrives)
                .fontSize(16)
                .fontColor(this.theme().mutedText)
                .margin({ top: 24 })
            } else {
              List() {
                ForEach(this.drives, (drive: StorageDrive) => {
                  ListItem() {
                    Row() {
                      Column() {
                        Text(drive.name)
                          .fontSize(18)
                          .fontColor(this.theme().text)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                        Text(this.driveTypeName(drive.type))
                          .fontSize(13)
                          .fontColor(this.theme().mutedText)
                          .margin({ top: 5 })
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)
                      Button(this.labels().open)
                        .height(36)
                        .onClick(() => this.openDrive(drive))
                      Button(this.labels().edit)
                        .height(36)
                        .margin({ left: 10 })
                        .onClick(() => this.editDrive(drive))
                      Button(this.labels().delete)
                        .height(36)
                        .margin({ left: 10 })
                        .backgroundColor('#7f1d1d')
                        .onClick(() => this.deleteDrive(drive))
                    }
                    .width('100%')
                    .padding(14)
                    .backgroundColor(this.theme().cardBg)
                    .borderRadius(12)
                  }
                  .margin({ top: 12 })
                }, (drive: StorageDrive) => `${drive.id}`)
              }
              .layoutWeight(1)
              .margin({ top: 12 })
            }
          } else {
            Row() {
              TextInput({ text: this.searchKeyword, placeholder: this.labels().searchPlaceholder })
                .height(40)
                .fontSize(14)
                .layoutWeight(1)
                .onChange((value: string) => this.updateSearchKeyword(value))
              Button(this.labels().clear)
                .height(40)
                .margin({ left: 10 })
                .enabled(this.searchKeyword.trim().length > 0)
                .onClick(() => this.clearSearchKeyword())
            }
            .width('100%')
            .margin({ top: 12 })
          }

          if (this.selectedDrive !== null && this.loading) {
            Column() {
              LoadingProgress().width(48).height(48).color(this.theme().primarySoft)
              Text(this.labels().loading)
                .fontSize(15)
                .fontColor(this.theme().mutedText)
                .margin({ top: 12 })
            }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else if (this.selectedDrive !== null && this.items.length === 0) {
            Text(this.allItems.length > 0 ? this.labels().noMatch : this.labels().emptyDir)
              .fontSize(16)
              .fontColor(this.theme().mutedText)
              .margin({ top: 24 })
          } else if (this.selectedDrive !== null) {
            List() {
              ForEach(this.items, (item: DriveFileItem) => {
                ListItem() {
                  Row() {
                    Text(item.isFile ? '>' : '[D]')
                      .fontSize(20)
                      .fontColor(item.isFile ? this.theme().primarySoft : '#fbbf24')
                      .width(34)
                    Column() {
                      Text(item.name)
                        .fontSize(17)
                        .fontColor(this.theme().text)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text(`${item.isFile ? item.fileType : this.labels().folderBadge} ${driveService.formatTime(item.lastModified)}`)
                        .fontSize(12)
                        .fontColor(this.theme().mutedText)
                        .margin({ top: 5 })
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                    Text(item.isFile ? (driveService.isVideoFile(item) ? this.labels().play : this.labels().file) : this.labels().enterFolder)
                      .fontSize(14)
                      .fontColor(this.theme().primarySoft)
                  }
                  .width('100%')
                  .padding(14)
                  .backgroundColor(this.theme().cardBg)
                  .borderRadius(12)
                  .onClick(() => this.openItem(item))
                }
                .margin({ top: 10 })
              }, (item: DriveFileItem) => item.path)
            }
            .layoutWeight(1)
            .margin({ top: 12 })
          }
        }
        .layoutWeight(1)
        .height('100%')
        .margin({ left: 18 })
        .padding(18)
        .backgroundColor(this.theme().fieldBg)
        .borderRadius(14)
      }
      .width('100%')
      .layoutWeight(1)
      .margin({ top: 18 })
    }
    .width('100%')
    .height('100%')
    .padding(40)
    .backgroundColor(this.theme().pageBg)
  }
}
