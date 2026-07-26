export type JsonNode = Object | null | undefined;

export function parseJson(text: string): JsonNode {
  return JSON.parse(text) as JsonNode;
}

export function asRecord(value: JsonNode): Record<string, JsonNode> {
  if (value !== null && value !== undefined && typeof value === 'object' && !Array.isArray(value)) {
    return value as Record<string, JsonNode>;
  }
  return {};
}

export function asArray(value: JsonNode): JsonNode[] {
  return Array.isArray(value) ? value as JsonNode[] : [];
}

export function safeString(record: Record<string, JsonNode>, key: string, fallback: string = ''): string {
  const value: JsonNode = record[key];
  if (value === undefined || value === null) {
    return fallback;
  }
  return String(value);
}

export function safeNumber(record: Record<string, JsonNode>, key: string, fallback: number = 0): number {
  const value: JsonNode = record[key];
  if (typeof value === 'number') {
    return value;
  }
  if (typeof value === 'string') {
    const parsed = Number(value);
    return Number.isNaN(parsed) ? fallback : parsed;
  }
  return fallback;
}

export function safeStringList(record: Record<string, JsonNode>, key: string): string[] {
  const value: JsonNode = record[key];
  if (!Array.isArray(value)) {
    return [];
  }
  return (value as JsonNode[]).map((item: JsonNode) => String(item));
}
