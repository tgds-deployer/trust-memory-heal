export function safeJsonParse<T = any>(input: unknown, fallback?: T): T | undefined {
    if (typeof input !== "string") return fallback;
    try {
        return JSON.parse(input);
    } catch {
        return fallback;
    }
}
