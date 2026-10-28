// Minimal, dependency-free smoke notes for manual testing.
// This repo has no test runner wired (see README "not yet done").
// The real verification for this delivery was done with curl against a
// running server (see README test section), not with a unit-test suite.
export const smokeNotes = [
  "GET /api/models returns a registry without keys",
  "POST /api/chat without a key returns MODEL_NOT_CONFIGURED, not a fake answer",
  "POST /api/chat with IDCX_MOCK_MODEL=1 streams delta chunks then done",
];
