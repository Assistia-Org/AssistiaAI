-- ClickHouse başlangıç scripti
-- AssistiaAI loglama altyapısı için logs tablosunu oluşturur

CREATE DATABASE IF NOT EXISTS assistia_logs;

CREATE TABLE IF NOT EXISTS assistia_logs.logs
(
    -- Zaman alanları
    timestamp       DateTime64(3, 'UTC'),
    event_date      Date DEFAULT toDate(timestamp),

    -- Log kimlik bilgileri
    level           LowCardinality(String),   -- DEBUG / INFO / WARNING / ERROR / CRITICAL
    event_type      LowCardinality(String),   -- AUTH_LOGIN, TASK_CREATE, API_ERROR, ...
    service         LowCardinality(String),   -- assistia-backend

    -- İstek bilgileri
    method          LowCardinality(String),   -- GET, POST, PUT, DELETE, PATCH
    path            String,
    status_code     UInt16,
    duration_ms     UInt32,

    -- Kullanıcı / Oturum
    user_id         String,
    username        String DEFAULT '',
    email           String DEFAULT '',
    ip_address      String,

    -- Log mesajı
    msg             String,

    -- Genişletilebilir alan (JSON string)
    extra           String DEFAULT '{}'
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(event_date)
ORDER BY (event_date, level, event_type, timestamp)
TTL event_date + INTERVAL 90 DAY          -- 90 günden eski kayıtları otomatik sil
SETTINGS index_granularity = 8192;
