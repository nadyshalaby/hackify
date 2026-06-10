// Corpus fixture: an env var validated in the schema but used nowhere.
// DATABASE_URL and SMTP_HOST are contrast controls — both validated AND read
// below — so the orphan is the one entry with no consumer anywhere.
const required = ['DATABASE_URL', 'SMTP_HOST', 'ANALYTICS_KEY'] // EXPECT-SEMANTIC: clean.orphan-env

export function validateEnv(env) {
  for (const name of required) {
    if (!env[name]) {
      return false
    }
  }
  return true
}

export function dbUrl(env) {
  return env.DATABASE_URL
}

export function smtpHost(env) {
  return env.SMTP_HOST
}
