export type JsonValue = string | number | boolean | null | JsonObject | JsonValue[];
export type JsonObject = Record<string, JsonValue>;

export function asRecord(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === 'object' && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return {};
}

export function asArray(value: unknown): unknown[] {
  return Array.isArray(value) ? value as unknown[] : [];
}

export function safeString(record: Record<string, unknown>, key: string, fallback: string = ''): string {
  const value = record[key];
  if (value === undefined || value === null) {
    return fallback;
  }
  return String(value);
}

export function safeNumber(record: Record<string, unknown>, key: string, fallback: number = 0): number {
  const value = record[key];
  if (typeof value === 'number') {
    return value;
  }
  if (typeof value === 'string') {
    const parsed = Number(value);
    return Number.isNaN(parsed) ? fallback : parsed;
  }
  return fallback;
}

export function safeStringList(record: Record<string, unknown>, key: string): string[] {
  const value = record[key];
  if (!Array.isArray(value)) {
    return [];
  }
  return value.map((item: unknown) => String(item));
}
