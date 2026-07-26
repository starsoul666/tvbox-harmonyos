import { PlaybackSession } from '../../domain/playback/PlaybackSession';

/**
 * Rendering surface only. Controls talk to `PlaybackSession`, never to this component.
 */
@Component
export struct PlayerSurface {
  session: PlaybackSession = new PlaybackSession();
  private controller: XComponentController = new XComponentController();

  build() {
    XComponent({
      id: 'tvbox_player_surface',
      type: XComponentType.SURFACE,
      controller: this.controller
    })
      .onLoad(() => {
        this.session.attachSurface(this.controller.getXComponentSurfaceId());
      })
      .width('100%')
      .height('100%')
  }
}
