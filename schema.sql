
-- Events table
CREATE TABLE IF NOT EXISTS collected_events (
    id BIGSERIAL PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    domain VARCHAR(255),
    url TEXT,
    data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_events_session ON collected_events(session_id);
CREATE INDEX IF NOT EXISTS idx_events_type ON collected_events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_domain ON collected_events(domain);
CREATE INDEX IF NOT EXISTS idx_events_created ON collected_events(created_at);
CREATE INDEX IF NOT EXISTS idx_events_data ON collected_events USING GIN (data);

-- Security alerts table
CREATE TABLE IF NOT EXISTS security_alerts (
    id BIGSERIAL PRIMARY KEY,
    session_id VARCHAR(255),
    severity VARCHAR(20) CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    alert_type VARCHAR(100),
    domain VARCHAR(255),
    details JSONB DEFAULT '{}',
    acknowledged BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Domain tracking table
CREATE TABLE IF NOT EXISTS domain_tracking (
    domain VARCHAR(255) PRIMARY KEY,
    first_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    total_visits BIGINT DEFAULT 0,
    unique_sessions BIGINT DEFAULT 0,
    is_suspicious BOOLEAN DEFAULT FALSE,
    risk_score INTEGER DEFAULT 0
);

-- Materialized view for analytics
CREATE MATERIALIZED VIEW IF NOT EXISTS domain_stats AS
SELECT 
    domain,
    COUNT(*) as total_events,
    COUNT(DISTINCT session_id) as unique_sessions,
    COUNT(CASE WHEN event_type = 'security_alert' THEN 1 END) as security_alerts,
    COUNT(CASE WHEN event_type LIKE '%turnstile%' THEN 1 END) as turnstile_events,
    MAX(created_at) as last_event
FROM collected_events
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY domain
ORDER BY total_events DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_domain_stats ON domain_stats(domain);

