-- =====================================================================
-- 01_schema.sql : star schema for the Market Risk Analytics Engine
-- Run as riskdesk_user:
--   psql -U riskdesk_user -d riskdesk -h localhost -f sql/01_schema.sql
-- Safe to re-run: IF NOT EXISTS skips tables that already exist.
-- =====================================================================

-- ---------- DIMENSION: dates ----------
-- One row per calendar day. is_trading_day is set after data is loaded.
CREATE TABLE IF NOT EXISTS dim_date (
    trade_date      DATE        PRIMARY KEY,
    year            SMALLINT    NOT NULL,
    quarter         SMALLINT    NOT NULL,
    month           SMALLINT    NOT NULL,
    month_name      TEXT        NOT NULL,
    week_of_year    SMALLINT    NOT NULL,
    day_of_week     SMALLINT    NOT NULL,   -- 1 = Monday ... 7 = Sunday (ISO)
    day_name        TEXT        NOT NULL,
    is_weekend      BOOLEAN     NOT NULL,
    is_trading_day  BOOLEAN     NOT NULL DEFAULT FALSE
);

-- ---------- DIMENSION: instruments ----------
-- One row per stock or derivative contract.
CREATE TABLE IF NOT EXISTS dim_instrument (
    instrument_id    SERIAL         PRIMARY KEY,
    symbol           TEXT           NOT NULL,             -- e.g. RELIANCE, NIFTY
    instrument_type  TEXT           NOT NULL,
    expiry_date      DATE,                                -- NULL for stocks
    strike_price     NUMERIC(12,2),                       -- NULL for stocks and futures
    option_type      CHAR(2),                             -- CE / PE, NULL otherwise
    isin             TEXT,                                -- stocks only
    lot_size         INTEGER,                             -- contract size (new-format files only)

    CONSTRAINT chk_instrument_type
        CHECK (instrument_type IN ('EQ', 'FUTIDX', 'FUTSTK', 'OPTIDX', 'OPTSTK')),
    CONSTRAINT chk_option_fields
        CHECK ((instrument_type LIKE 'OPT%') = (option_type IS NOT NULL)),
    CONSTRAINT chk_option_type
        CHECK (option_type IN ('CE', 'PE')),
    CONSTRAINT uq_instrument
        UNIQUE NULLS NOT DISTINCT (symbol, instrument_type, expiry_date, strike_price, option_type)
);

-- ---------- FACT: daily equity prices ----------
-- Grain: one stock on one trading day.
CREATE TABLE IF NOT EXISTS fact_eq_daily (
    trade_date      DATE           NOT NULL REFERENCES dim_date(trade_date),
    instrument_id   INTEGER        NOT NULL REFERENCES dim_instrument(instrument_id),
    open_price      NUMERIC(12,2),
    high_price      NUMERIC(12,2),
    low_price       NUMERIC(12,2),
    close_price     NUMERIC(12,2)  NOT NULL,
    prev_close      NUMERIC(12,2),
    volume          BIGINT,                               -- shares traded
    turnover        NUMERIC(20,2),                        -- value traded, in rupees
    num_trades      BIGINT,
    PRIMARY KEY (trade_date, instrument_id)
);

-- ---------- FACT: daily F&O prices ----------
-- Grain: one derivative contract on one trading day.
CREATE TABLE IF NOT EXISTS fact_fno_daily (
    trade_date        DATE           NOT NULL REFERENCES dim_date(trade_date),
    instrument_id     INTEGER        NOT NULL REFERENCES dim_instrument(instrument_id),
    open_price        NUMERIC(12,2),
    high_price        NUMERIC(12,2),
    low_price         NUMERIC(12,2),
    close_price       NUMERIC(12,2),
    settle_price      NUMERIC(12,2),                      -- official mark-to-market price
    underlying_price  NUMERIC(12,2),                      -- only present in the new format
    open_interest     BIGINT,
    change_in_oi      BIGINT,
    volume            BIGINT,
    turnover          NUMERIC(20,2),
    PRIMARY KEY (trade_date, instrument_id)
);

-- ---------- BOOKKEEPING: which files have been loaded ----------
-- Lets the loader skip days already done, so re-running it is safe.
CREATE TABLE IF NOT EXISTS etl_load_log (
    trade_date     DATE         NOT NULL,
    segment        TEXT         NOT NULL CHECK (segment IN ('CM', 'FO')),
    source_format  TEXT         NOT NULL CHECK (source_format IN ('legacy', 'udiff')),
    rows_loaded    INTEGER      NOT NULL,
    loaded_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    PRIMARY KEY (trade_date, segment)
);

-- ---------- INDEXES for "one instrument over time" queries ----------
CREATE INDEX IF NOT EXISTS ix_eq_instrument_date  ON fact_eq_daily  (instrument_id, trade_date);
CREATE INDEX IF NOT EXISTS ix_fno_instrument_date ON fact_fno_daily (instrument_id, trade_date);
CREATE INDEX IF NOT EXISTS ix_instrument_symbol   ON dim_instrument (symbol, instrument_type);