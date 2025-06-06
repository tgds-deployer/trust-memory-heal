// Healing logic integration © 2025 DevExcelsior — Licensed only via BUSL 1.1

import { createAdapter } from '@devexcelsior/wrap'

export const healingReplay = createAdapter({
    on(event, cb) {
        console.log(`[healing] intercepted event: ${event}`)
        cb({ type: event, ts: Date.now() })
    },
    sessionId: 'stub-session-123',
})
