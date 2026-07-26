/**
 * Episode ordering helpers shared by Detail and Play.
 * Android keeps the reverse flag on `VodInfo.reverseSort` and applies it to the visible list,
 * so next/previous always operate on the visible order.
 */

export function nextEpisodeIndex(index: number, count: number): number {
  const next = index + 1;
  return next >= 0 && next < count ? next : -1;
}

export function previousEpisodeIndex(index: number, count: number): number {
  const previous = index - 1;
  return previous >= 0 && previous < count ? previous : -1;
}

/** Android `DetailActivity` reverse button reverses the visible episode list in place. */
export function visibleOrder<T>(items: T[], reverse: boolean): T[] {
  return reverse ? items.slice().reverse() : items.slice();
}

/** Maps a visible-list index back to the underlying source index. */
export function toSourceIndex(visibleIndex: number, count: number, reverse: boolean): number {
  return reverse ? count - 1 - visibleIndex : visibleIndex;
}
