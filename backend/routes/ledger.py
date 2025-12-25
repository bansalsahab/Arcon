from flask import Blueprint, jsonify, request, Response
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..models.ledger import LedgerEntry
import csv
import io

ledger_bp = Blueprint("ledger", __name__, url_prefix="/api/ledger")


@ledger_bp.get("")
@jwt_required()
def list_ledger():
    """
    ---
    tags: [Ledger]
    summary: List ledger entries
    security:
      - BearerAuth: []
    parameters:
      - in: query
        name: limit
        type: integer
        required: false
        default: 100
      - in: query
        name: offset
        type: integer
        required: false
        default: 0
    responses:
      200:
        description: Recent ledger entries
    """
    user_id = int(get_jwt_identity())
    try:
        limit = int(request.args.get("limit", 100))
    except ValueError:
        limit = 100
    try:
        offset = int(request.args.get("offset", 0))
    except ValueError:
        offset = 0
    items = (
        LedgerEntry.query
        .filter_by(user_id=user_id)
        .order_by(LedgerEntry.timestamp.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return jsonify([e.to_dict() for e in items])


@ledger_bp.get("/export")
@jwt_required()
def export_ledger():
    """
    ---
    tags: [Ledger]
    summary: Export ledger entries as CSV
    security:
      - BearerAuth: []
    parameters:
      - in: query
        name: limit
        type: integer
        required: false
        default: 1000
    responses:
      200:
        description: CSV file contents
    """
    user_id = int(get_jwt_identity())
    try:
        limit = int(request.args.get("limit", 1000))
    except ValueError:
        limit = 1000
    items = (
        LedgerEntry.query
        .filter_by(user_id=user_id)
        .order_by(LedgerEntry.timestamp.desc())
        .limit(limit)
        .all()
    )
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["id", "timestamp", "type", "category", "amount_paise", "reference_type", "reference_id"])
    for e in items:
        writer.writerow([
            e.id,
            e.timestamp.isoformat() if e.timestamp else "",
            e.type,
            e.category,
            e.amount_paise,
            e.reference_type,
            e.reference_id,
        ])
    csv_data = output.getvalue()
    return Response(csv_data, mimetype="text/csv", headers={
        "Content-Disposition": "attachment; filename=ledger.csv"
    })
