"""
Database migration to add UPI AutoPay mandate tracking columns.

Adds:
- failure_count: Track failed debit attempts
- last_failure_reason: Store reason for last failure
- pre_debit_notification_sent_at: Compliance tracking for 24h notice
- auth_link: Store UPI authorization link from Razorpay

Run with: flask db upgrade (if using Flask-Migrate)
Or manually execute SQL against your database.
"""

# Manual SQL for SQLite/PostgreSQL:

ALTER_MANDATES_TABLE_SQL = """
ALTER TABLE mandates 
ADD COLUMN failure_count INTEGER DEFAULT 0,
ADD COLUMN last_failure_reason TEXT,
ADD COLUMN pre_debit_notification_sent_at TIMESTAMP,
ADD COLUMN auth_link TEXT;
"""

# If using Flask-Migrate, this would be in a migration file:
# migrations/versions/xxx_add_mandate_tracking_fields.py

def upgrade():
    """Add mandate tracking fields."""
    op.add_column('mandates', sa.Column('failure_count', sa.Integer(), default=0))
    op.add_column('mandates', sa.Column('last_failure_reason', sa.Text(), nullable=True))
    op.add_column('mandates', sa.Column('pre_debit_notification_sent_at', sa.DateTime(), nullable=True))
    op.add_column('mandates', sa.Column('auth_link', sa.Text(), nullable=True))


def downgrade():
    """Remove mandate tracking fields."""
    op.drop_column('mandates', 'auth_link')
    op.drop_column('mandates', 'pre_debit_notification_sent_at')
    op.drop_column('mandates', 'last_failure_reason')
    op.drop_column('mandates', 'failure_count')
