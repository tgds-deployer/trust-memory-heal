// Merge diffing + memory-based fallback

export function mergeWithMemory(currentState: any, replaySnapshot: any) {
    return {
        ...replaySnapshot,
        ...currentState,
        resolvedAt: new Date().toISOString(),
    }
}
