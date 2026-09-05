"""baseline database schema

Revision ID: f7ab4524643a
Revises: 059b3615e1f3
Create Date: 2026-09-05 16:03:15.365354

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f7ab4524643a'
down_revision: Union[str, Sequence[str], None] = '059b3615e1f3'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
