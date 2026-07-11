import cryptoFramework from '@ohos.security.cryptoFramework';
import util from '@ohos.util';

function utf8Bytes(input: string): Uint8Array {
  return util.TextEncoder.create('utf-8').encodeInto(input);
}

function utf8Text(bytes: Uint8Array): string {
  return util.TextDecoder.create('utf-8').decode(bytes);
}

export function isJsonText(content: string): boolean {
  try {
    const parsed: unknown = JSON.parse(content);
    return typeof parsed === 'object' && parsed !== null;
  } catch (_error) {
    return false;
  }
}

export function rightPadding(input: string, replacement: string, targetLength: number): string {
  const trimmed = input.trim();
  if (trimmed.length >= targetLength) {
    return trimmed.substring(0, targetLength);
  }
  let result = trimmed;
  while (result.length < targetLength) {
    result += replacement;
  }
  return result.substring(0, targetLength);
}

export function hexToBytes(input: string): Uint8Array {
  const length = Math.floor(input.length / 2);
  const result = new Uint8Array(length);
  for (let index = 0; index < length; index += 1) {
    const start = index * 2;
    result[index] = parseInt(input.substring(start, start + 2), 16);
  }
  return result;
}

function decryptAes(cipherTextHex: string, keyText: string, ivText?: string): string {
  const generator = cryptoFramework.createSymKeyGenerator('AES128');
  const key = generator.convertKeySync({ data: utf8Bytes(keyText) });
  const transformation = ivText ? 'AES128|CBC|PKCS7' : 'AES128|ECB|PKCS7';
  const cipher = cryptoFramework.createCipher(transformation);
  const params: cryptoFramework.IvParamsSpec | null = ivText
    ? { algName: 'IvParamsSpec', iv: { data: utf8Bytes(ivText) } }
    : null;
  cipher.initSync(cryptoFramework.CryptoMode.DECRYPT_MODE, key, params);
  return utf8Text(cipher.doFinalSync({ data: hexToBytes(cipherTextHex) }).data);
}

export function decryptEcb(cipherTextHex: string, keyText: string): string {
  return decryptAes(cipherTextHex, rightPadding(keyText, '0', 16));
}

export function decryptCbc(cipherTextHex: string, keyText: string, ivText: string): string {
  return decryptAes(cipherTextHex, keyText, ivText);
}
