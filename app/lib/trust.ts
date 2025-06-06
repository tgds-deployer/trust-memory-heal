// Trust-weighted arbitration logic

export function calculateTrustScore(events: any[]): number {
    const highImpact = events.filter(e => e.impactScore > 0.6).length
    return highImpact / (events.length || 1)
}
