"""
Load six CSV source files into PostgreSQL Bronze tables.

Expected location: <project-root>/scripts/bronze/load_bronze.py
Expected folders: <project-root>/datasets/source_crm and source_erp
All six tables are refreshed in one transaction. If a load fails, the batch
rolls back and the previous Bronze data remains intact.

Command-line usage:
    python scripts/bronze/load_bronze.py
"""
from __future__ import annotations

import logging
import os
import sys
import time
from pathlib import Path

import psycopg
from psycopg import sql
from dotenv import load_dotenv

# Resolve the project root from: <root>/scripts/bronze/load_bronze.py
PROJECT_ROOT = Path(__file__).resolve().parents[2]
DATASET_ROOT = PROJECT_ROOT / "datasets"

# Read configuration from the .env file in the project root.
load_dotenv(PROJECT_ROOT / ".env")

# Fixed source-to-target mapping. Use the exact CSV filenames in the repository.
INGESTION_JOBS = [
    {"table": ("bronze", "crm_cust_info"),
     "file": DATASET_ROOT / "source_crm" / "cust_info.csv"},
    {"table": ("bronze", "crm_prd_info"),
     "file": DATASET_ROOT / "source_crm" / "prd_info.csv"},
    {"table": ("bronze", "crm_sales_details"),
     "file": DATASET_ROOT / "source_crm" / "sales_details.csv"},
    {"table": ("bronze", "erp_cust_az12"),
     "file": DATASET_ROOT / "source_erp" / "CUST_AZ12.csv"},
    {"table": ("bronze", "erp_loc_a101"),
     "file": DATASET_ROOT / "source_erp" / "LOC_A101.csv"},
    {"table": ("bronze", "erp_px_cat_g1v2"),
     "file": DATASET_ROOT / "source_erp" / "PX_CAT_G1V2.csv"},
]

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


def get_connection_settings() -> dict:
    """Read connection settings and fail early if required values are missing."""
    required = ("DB_NAME", "DB_USER", "DB_PASSWORD")
    missing = [key for key in required if not os.getenv(key)]
    if missing:
        raise RuntimeError("Missing .env setting(s): " + ", ".join(missing))

    return {
        "dbname": os.environ["DB_NAME"],
        "user": os.environ["DB_USER"],
        "password": os.environ["DB_PASSWORD"],
        "host": os.getenv("DB_HOST", "localhost"),
        "port": int(os.getenv("DB_PORT", "5432")),
        "connect_timeout": 10,
    }


def validate_inputs() -> None:
    """Verify every CSV exists before any target table is truncated."""
    missing = [str(job["file"]) for job in INGESTION_JOBS
               if not Path(job["file"]).is_file()]
    if missing:
        raise FileNotFoundError(
            "Source file(s) not found:\n- " + "\n- ".join(missing)
        )
    logger.info("Validated all %d source files.", len(INGESTION_JOBS))


def copy_csv_to_table(conn: psycopg.Connection,
                      table: tuple[str, str],
                      csv_path: Path) -> int:
    """Stream one CSV into PostgreSQL using COPY FROM STDIN."""
    schema_name, table_name = table
    statement = sql.SQL(
        """
        COPY {}.{} FROM STDIN
        WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',', QUOTE '"', NULL '')
        """
    ).format(sql.Identifier(schema_name), sql.Identifier(table_name))

    with conn.cursor() as cur:
        # utf-8-sig also handles a UTF-8 BOM if one is present.
        with csv_path.open("r", encoding="utf-8-sig", newline="") as source:
            with cur.copy(statement) as copy_stream:
                while chunk := source.read(1024 * 1024):
                    copy_stream.write(chunk)
        return cur.rowcount


def run_pipeline() -> int:
    """Refresh all six Bronze tables as one atomic batch."""
    batch_start = time.perf_counter()
    current_table = "pre-load validation"
    metrics: list[tuple[str, float, int]] = []

    try:
        validate_inputs()
        settings = get_connection_settings()

        logger.info("=" * 64)
        logger.info("Starting Bronze ingestion for %d tables.", len(INGESTION_JOBS))
        logger.info("All table truncations and loads share one transaction.")
        logger.info("=" * 64)

        # psycopg commits when this connection context exits successfully;
        # an exception causes the transaction to roll back.
        with psycopg.connect(**settings) as conn:
            logger.info("Truncating all Bronze tables before loading new data...")
            with conn.cursor() as cur:
                cur.execute(
                    """
                    TRUNCATE TABLE
                        bronze.crm_cust_info,
                        bronze.crm_prd_info,
                        bronze.crm_sales_details,
                        bronze.erp_cust_az12,
                        bronze.erp_loc_a101,
                        bronze.erp_px_cat_g1v2
                    """
                )

            for job in INGESTION_JOBS:
                logger.info("Processing ingestion job for %s", job["table"])
                schema_name, table_name = job["table"]
                current_table = f"{schema_name}.{table_name}"
                csv_path = Path(job["file"])
                table_start = time.perf_counter()

                logger.info("Loading %s from %s", current_table, csv_path.name)
                rows_loaded = copy_csv_to_table(conn, job["table"], csv_path)
                duration = time.perf_counter() - table_start
                metrics.append((current_table, duration, rows_loaded))
                logger.info(
                    "Loaded %d rows into %s in %.2f seconds.",
                    rows_loaded, current_table, duration
                )

        # Reaching this point means the database transaction committed.
        logger.info("=" * 64)
        logger.info("Bronze ingestion completed and committed successfully.")
        for table, duration, rows in metrics:
            logger.info("%-30s | rows: %8d | duration: %7.2fs",
                        table, rows, duration)
        logger.info("Total duration: %.2f seconds",
                    time.perf_counter() - batch_start)
        logger.info("=" * 64)
        return 0

    except Exception:
        logger.exception(
            "Bronze ingestion failed while processing %s. "
            "The transaction was rolled back if it had started.",
            current_table,
        )
        return 1


if __name__ == "__main__":
    sys.exit(run_pipeline())
