export function errorMessage(error: Error | string | null | undefined): string {
  if (error === null || error === undefined) {
    return 'unknown error';
  }
  if (typeof error === 'string') {
    return error;
  }
  const message: string = error.message;
  return message.length === 0 ? String(error) : message;
}
