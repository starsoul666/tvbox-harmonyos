import util from '@ohos.util';

const textEncoder: util.TextEncoder = new util.TextEncoder();
const base64Helper: util.Base64Helper = new util.Base64Helper();

/** Android `Base64.encodeToString(..., NO_WRAP)` equivalent for filter `ext` payloads. */
export function base64Encode(value: string): string {
  if (value.length === 0) {
    return '';
  }
  return base64Helper.encodeToStringSync(textEncoder.encodeInto(value));
}
