import cryptoFramework from '@ohos.security.cryptoFramework';
import util from '@ohos.util';

export function bytesToHex(bytes: Uint8Array): string {
  const hex = '0123456789abcdef';
  let result = '';
  for (let index = 0; index < bytes.length; index += 1) {
    const value = bytes[index];
    result += hex[(value >> 4) & 0x0f] + hex[value & 0x0f];
  }
  return result;
}

export function md5Hex(input: string): string {
  const encoder = util.TextEncoder.create('utf-8');
  const md = cryptoFramework.createMd('MD5');
  md.updateSync({ data: encoder.encodeInto(input) });
  return bytesToHex(md.digestSync().data);
}
