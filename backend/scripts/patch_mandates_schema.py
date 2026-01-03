import sqlite3
from pathlib import Path


def patch_db(db_path: Path) -> None:
    if not db_path.exists():
        print(f"Skipping {db_path} (not found)")
        return

    print(f"Patching {db_path}")
    conn = sqlite3.connect(str(db_path))
    cur = conn.cursor()

    # Inspect existing columns on mandates table
    cur.execute("PRAGMA table_info(mandates)")
    cols = {row[1] for row in cur.fetchall()}
    print("Existing columns:", sorted(cols))

    def add(col: str, ddl: str) -> None:
        if col in cols:
            print(f"  Column already exists: {col}")
            return
        print(f"  Adding column: {col}")
        cur.execute(ddl)

    add("failure_count", "ALTER TABLE mandates ADD COLUMN failure_count INTEGER DEFAULT 0")
    add("last_failure_reason", "ALTER TABLE mandates ADD COLUMN last_failure_reason TEXT")
    add("pre_debit_notification_sent_at", "ALTER TABLE mandates ADD COLUMN pre_debit_notification_sent_at DATETIME")
    add("auth_link", "ALTER TABLE mandates ADD COLUMN auth_link TEXT")

    conn.commit()
    conn.close()


def main() -> None:
    script_dir = Path(__file__).resolve()
    backend_root = script_dir.parents[1]
    project_root = script_dir.parents[2]

    db_paths = [
        backend_root / "instance" / "roundup.db",   # active when running python -m backend.app
        project_root / "instance" / "roundup.db",   # older instance db at project root
    ]

    for p in db_paths:
        patch_db(p)


if __name__ == "__main__":
    main()
