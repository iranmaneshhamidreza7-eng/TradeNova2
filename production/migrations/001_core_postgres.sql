-- PostgreSQL starter schema. Review with a qualified backend/security engineer before production.
CREATE TABLE IF NOT EXISTS app_users (
  id TEXT PRIMARY KEY,
  telegram_user_id BIGINT UNIQUE,
  username TEXT,
  country_code CHAR(2),
  language_code VARCHAR(12) NOT NULL DEFAULT 'en',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','disabled','review'))
);
CREATE TABLE IF NOT EXISTS money_requests (
  id UUID PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES app_users(id),
  kind TEXT NOT NULL CHECK (kind IN ('deposit','withdrawal')),
  amount NUMERIC(24,8) NOT NULL CHECK (amount > 0),
  currency VARCHAR(12) NOT NULL,
  provider TEXT NOT NULL,
  provider_reference TEXT,
  idempotency_key TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL CHECK (status IN ('created','pending','approved','rejected','processing','paid','failed','cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(provider, provider_reference)
);
CREATE TABLE IF NOT EXISTS ledger_transactions (
  id UUID PRIMARY KEY,
  request_id UUID UNIQUE REFERENCES money_requests(id),
  external_reference TEXT UNIQUE,
  currency VARCHAR(12) NOT NULL,
  status TEXT NOT NULL DEFAULT 'posted' CHECK (status IN ('pending','posted','reversed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS ledger_entries (
  id BIGSERIAL PRIMARY KEY,
  transaction_id UUID NOT NULL REFERENCES ledger_transactions(id),
  account_code TEXT NOT NULL,
  amount NUMERIC(24,8) NOT NULL CHECK (amount <> 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS provider_events (
  provider TEXT NOT NULL,
  event_id TEXT NOT NULL,
  received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed_at TIMESTAMPTZ,
  payload_hash TEXT NOT NULL,
  PRIMARY KEY(provider, event_id)
);
CREATE TABLE IF NOT EXISTS audit_log (
  id BIGSERIAL PRIMARY KEY,
  actor_id TEXT NOT NULL,
  action TEXT NOT NULL,
  target_type TEXT NOT NULL,
  target_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS money_requests_user_created_idx ON money_requests(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS audit_log_target_idx ON audit_log(target_type, target_id, created_at DESC);
