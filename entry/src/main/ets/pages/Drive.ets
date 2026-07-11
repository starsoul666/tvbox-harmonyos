import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { HawkConfig } from '../constants/HawkConfig';
import { DriveFileItem, DriveType, StorageDrive, VodInfo } from '../models/TvBoxModels';
import { driveDataStore } from '../services/DriveDataStore';
import { driveService } from '../services/DriveService';
import { settingsStore } from '../services/SettingsStore';
import { vodDataStore } from '../services/VodDataStore';

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
  @State statusText: string = '支持添加本地目录、Alist、WebDAV 并浏览播放视频文件';
  @State loading: boolean = false;
  @State sortType: number = 0;
  @State searchKeyword: string = '';

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    this.sortType = await settingsStore.get<number>(HawkConfig.STORAGE_DRIVE_SORT, 0);
    this.refreshDrives();
  }

  refreshDrives(): void {
    this.drives = driveDataStore.getAll();
  }

  async saveDrive(): Promise<void> {
    const name = this.nameInput.trim();
    const url = this.urlInput.trim();
    if (name.length === 0 || (this.driveTypeInput !== DriveType.LOCAL && url.length === 0)) {
      this.statusText = this.driveTypeInput === DriveType.LOCAL ? '请填写本地目录绝对路径' : '请填写名称和网盘地址';
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
      this.statusText = '当前仅支持编辑本地目录、Alist、WebDAV 配置';
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
    this.statusText = `正在编辑：${drive.name}`;
  }

  resetEditor(): void {
    this.clearEditorFields();
    this.statusText = '已清空编辑区';
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
      this.statusText = '未知网盘类型';
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
      this.statusText = '未知网盘类型';
      return;
    }
    this.loading = true;
    this.statusText = `正在加载：${this.currentPath}`;
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
      this.statusText = `已加载 ${this.allItems.length} 项：${this.currentPath}`;
    } catch (error) {
      this.items = [];
      this.allItems = [];
      this.statusText = `加载失败：${this.stringifyError(error)}`;
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
        this.statusText = `已加载 ${this.allItems.length} 项：${this.currentPath}`;
      }
      return;
    }
    this.items = this.allItems.filter((item: DriveFileItem) => item.name.toLowerCase().includes(keyword));
    this.statusText = `搜索 "${this.searchKeyword.trim()}"：${this.items.length}/${this.allItems.length} 项`;
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
      this.statusText = `非视频文件：${item.name}`;
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
      vod.playerCfg = JSON.stringify({
        headers: [{ name: 'authorization', value: authorization }]
      });
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
      this.statusText = '已回到网盘列表';
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
      this.statusText = '已删除当前网盘';
    }
    if (this.editDriveId === drive.id) {
      this.resetEditor();
    }
    this.refreshDrives();
  }

  sortName(): string {
    switch (this.sortType) {
      case 1:
        return '名称降序';
      case 2:
        return '时间升序';
      case 3:
        return '时间降序';
      default:
        return '名称升序';
    }
  }

  browserTitle(): string {
    if (this.selectedDrive === null) {
      return '网盘列表';
    }
    return `${this.selectedDrive.name}  ${this.currentPath}`;
  }

  driveTypeName(type: number): string {
    if (type === DriveType.LOCAL) {
      return '本地目录';
    }
    if (type === DriveType.WEBDAV) {
      return 'WebDAV';
    }
    if (type === DriveType.ALISTWEB) {
      return 'Alist网页';
    }
    return `类型 ${type}`;
  }

  driveTypeInputName(): string {
    if (this.driveTypeInput === DriveType.LOCAL) {
      return '本地目录';
    }
    return this.driveTypeInput === DriveType.WEBDAV ? 'WebDAV' : 'Alist';
  }

  stringifyError(error: unknown): string {
    if (error instanceof Error) {
      return error.message;
    }
    const text = JSON.stringify(error);
    return text === undefined || text.length === 0 ? String(error) : text;
  }

  build() {
    Column() {
      Row() {
        Text('< 返回')
          .fontSize(18)
          .fontColor(Color.White)
          .onClick(() => router.back())
        Text('网盘')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ left: 24 })
          .layoutWeight(1)
        Button(`排序：${this.sortName()}`)
          .height(40)
          .onClick(() => this.changeSortType())
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.statusText)
        .fontSize(14)
        .fontColor('#93a4b8')
        .margin({ top: 12 })
        .width('100%')

      Row() {
        Column() {
          Text(`${this.editDriveId > 0 ? '编辑' : '添加'}${this.driveTypeInputName()}`)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
          if (this.editDriveId > 0) {
            Text(`编辑记录 #${this.editDriveId}`)
              .fontSize(13)
              .fontColor('#93a4b8')
              .margin({ top: 6 })
          }
          Row() {
            Button('本地')
              .height(36)
              .layoutWeight(1)
              .backgroundColor(this.driveTypeInput === DriveType.LOCAL ? '#2563eb' : '#374151')
              .onClick(() => this.driveTypeInput = DriveType.LOCAL)
            Button('Alist')
              .height(36)
              .layoutWeight(1)
              .margin({ left: 10 })
              .backgroundColor(this.driveTypeInput === DriveType.ALISTWEB ? '#2563eb' : '#374151')
              .onClick(() => this.driveTypeInput = DriveType.ALISTWEB)
            Button('WebDAV')
              .height(36)
              .layoutWeight(1)
              .margin({ left: 10 })
              .backgroundColor(this.driveTypeInput === DriveType.WEBDAV ? '#2563eb' : '#374151')
              .onClick(() => this.driveTypeInput = DriveType.WEBDAV)
          }
          .margin({ top: 12 })
          TextInput({
            text: this.nameInput,
            placeholder: this.driveTypeInput === DriveType.LOCAL ? '本地目录绝对路径，例如 /data/storage/el2/base/files' : '名称'
          })
            .height(44)
            .fontSize(15)
            .margin({ top: 12 })
            .onChange((value: string) => this.nameInput = value)
          if (this.driveTypeInput !== DriveType.LOCAL) {
            TextInput({
              text: this.urlInput,
              placeholder: this.driveTypeInput === DriveType.WEBDAV
                ? 'WebDAV 地址，例如 https://example.com/dav'
                : 'Alist 地址，例如 https://alist.example.com'
            })
              .height(44)
              .fontSize(15)
              .margin({ top: 10 })
              .onChange((value: string) => this.urlInput = value)
            if (this.driveTypeInput === DriveType.WEBDAV) {
              TextInput({ text: this.usernameInput, placeholder: 'WebDAV 用户名，可为空' })
                .height(44)
                .fontSize(15)
                .margin({ top: 10 })
                .onChange((value: string) => this.usernameInput = value)
            }
            TextInput({
              text: this.passwordInput,
              placeholder: this.driveTypeInput === DriveType.WEBDAV ? 'WebDAV 密码，可为空' : '访问密码，可为空'
            })
              .height(44)
              .fontSize(15)
              .margin({ top: 10 })
              .onChange((value: string) => this.passwordInput = value)
            TextInput({ text: this.initPathInput, placeholder: '初始路径，默认 /' })
              .height(44)
              .fontSize(15)
              .margin({ top: 10 })
              .onChange((value: string) => this.initPathInput = value)
          } else {
            Text('HarmonyOS Next 受系统沙箱限制，普通应用通常只能读取授权目录或应用可访问目录；这里先提供 Android StorageDrive 兼容的本地路径记录与浏览。')
              .fontSize(12)
              .fontColor('#93a4b8')
              .margin({ top: 10 })
          }
          Row() {
            Button(this.editDriveId > 0 ? '保存修改' : '保存并打开')
              .height(42)
              .layoutWeight(1)
              .onClick(() => this.saveDrive())
            Button('清空')
              .height(42)
              .margin({ left: 10 })
              .onClick(() => this.resetEditor())
          }
          .margin({ top: 12 })
        }
        .width(360)
        .padding(18)
        .backgroundColor('#111827')
        .borderRadius(14)

        Column() {
          Row() {
            Text(this.browserTitle())
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            if (this.selectedDrive !== null) {
              Button('上级')
                .height(38)
                .onClick(() => this.goUp())
            }
          }
          .width('100%')

          if (this.selectedDrive === null) {
            if (this.drives.length === 0) {
              Text('暂无网盘，先添加一个本地目录、Alist 或 WebDAV。')
                .fontSize(16)
                .fontColor('#d1d5db')
                .margin({ top: 24 })
            } else {
              List() {
                ForEach(this.drives, (drive: StorageDrive) => {
                  ListItem() {
                    Row() {
                      Column() {
                        Text(drive.name)
                          .fontSize(18)
                          .fontColor(Color.White)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                        Text(this.driveTypeName(drive.type))
                          .fontSize(13)
                          .fontColor('#93a4b8')
                          .margin({ top: 5 })
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)
                      Button('打开')
                        .height(36)
                        .onClick(() => this.openDrive(drive))
                      Button('编辑')
                        .height(36)
                        .margin({ left: 10 })
                        .onClick(() => this.editDrive(drive))
                      Button('删除')
                        .height(36)
                        .margin({ left: 10 })
                        .backgroundColor('#7f1d1d')
                        .onClick(() => this.deleteDrive(drive))
                    }
                    .width('100%')
                    .padding(14)
                    .backgroundColor('#151d2b')
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
              TextInput({ text: this.searchKeyword, placeholder: '搜索当前目录文件名' })
                .height(40)
                .fontSize(14)
                .layoutWeight(1)
                .onChange((value: string) => this.updateSearchKeyword(value))
              Button('清空')
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
              LoadingProgress().width(48).height(48).color('#60a5fa')
              Text('加载中...')
                .fontSize(15)
                .fontColor('#d1d5db')
                .margin({ top: 12 })
            }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else if (this.selectedDrive !== null && this.items.length === 0) {
            Text(this.allItems.length > 0 ? '没有匹配项' : '当前目录为空')
              .fontSize(16)
              .fontColor('#d1d5db')
              .margin({ top: 24 })
          } else if (this.selectedDrive !== null) {
            List() {
              ForEach(this.items, (item: DriveFileItem) => {
                ListItem() {
                  Row() {
                    Text(item.isFile ? '>' : '[D]')
                      .fontSize(20)
                      .fontColor(item.isFile ? '#60a5fa' : '#fbbf24')
                      .width(34)
                    Column() {
                      Text(item.name)
                        .fontSize(17)
                        .fontColor(Color.White)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text(`${item.isFile ? item.fileType : '目录'} ${driveService.formatTime(item.lastModified)}`)
                        .fontSize(12)
                        .fontColor('#93a4b8')
                        .margin({ top: 5 })
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                    Text(item.isFile ? (driveService.isVideoFile(item) ? '播放' : '文件') : '打开')
                      .fontSize(14)
                      .fontColor('#60a5fa')
                  }
                  .width('100%')
                  .padding(14)
                  .backgroundColor('#151d2b')
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
        .backgroundColor('#111827')
        .borderRadius(14)
      }
      .width('100%')
      .layoutWeight(1)
      .margin({ top: 18 })
    }
    .width('100%')
    .height('100%')
    .padding(40)
    .backgroundColor('#0b1020')
  }
}
