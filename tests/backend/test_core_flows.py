import json


def auth_headers(token: str):
    return {"Authorization": f"Bearer {token}"}


def register_and_login(client):
    r = client.post("/api/auth/register", json={
        "email": "user@example.com",
        "password": "secret",
        "full_name": "Test User"
    })
    assert r.status_code == 200, r.data
    token = r.get_json()["access_token"]
    return token


def test_auth_register_login_me(client):
    token = register_and_login(client)
    r = client.get("/api/auth/me", headers=auth_headers(token))
    assert r.status_code == 200
    data = r.get_json()
    assert data["email"] == "user@example.com"


def test_transactions_roundups_and_pending(client):
    token = register_and_login(client)
    # Create transaction
    r = client.post("/api/transactions", headers=auth_headers(token), json={
        "amount": 247.00,
        "merchant": "Test Shop"
    })
    assert r.status_code == 200, r.data
    data = r.get_json()
    assert data["transaction"]["amount_paise"] == 24700
    # Roundup should be created
    r = client.get("/api/roundups/pending", headers=auth_headers(token))
    assert r.status_code == 200
    pending = r.get_json()
    assert pending["total_paise"] > 0
    assert len(pending["items"]) == 1


def test_mandate_and_execute_investment(client):
    token = register_and_login(client)
    # Create mandate
    r = client.post("/api/mandates", headers=auth_headers(token))
    assert r.status_code == 200
    # Create multiple transactions
    for amt in [247.00, 152.50, 99.99]:
        client.post("/api/transactions", headers=auth_headers(token), json={"amount": amt, "merchant": "Shop"})
    # Execute investment
    r = client.post("/api/investments/execute", headers=auth_headers(token), json={})
    assert r.status_code == 200, r.data
    order = r.get_json()
    assert order["status"] == "executed"
    # Pending should be zero now
    r = client.get("/api/roundups/pending", headers=auth_headers(token))
    total = r.get_json()["total_paise"]
    assert total == 0
    # Portfolio should show invested
    r = client.get("/api/portfolio", headers=auth_headers(token))
    port = r.get_json()
    assert port["invested_total_paise"] > 0


def test_execute_allocated(client):
    token = register_and_login(client)
    # Mandate
    client.post("/api/mandates", headers=auth_headers(token))
    # A few transactions
    for amt in [50.10, 75.40, 199.95, 10.00]:
        client.post("/api/transactions", headers=auth_headers(token), json={"amount": amt})
    # Execute allocated
    r = client.post("/api/investments/execute/allocated", headers=auth_headers(token))
    assert r.status_code == 200, r.data
    data = r.get_json()
    assert "orders" in data
    assert len(data["orders"]) >= 1


def test_kyc_and_allocations(client):
    token = register_and_login(client)
    # Default allocations
    r = client.get("/api/allocations", headers=auth_headers(token))
    assert r.status_code == 200
    # Start and verify KYC
    r = client.post("/api/kyc/start", headers=auth_headers(token), json={
        "pan": "ABCDE1234F",
        "aadhaar_last4": "1234",
    })
    assert r.status_code == 200
    r = client.post("/api/kyc/verify", headers=auth_headers(token))
    assert r.status_code == 200
    assert r.get_json()["status"] == "verified"


def test_notifications_and_events_and_csv(client):
    token = register_and_login(client)
    # Create a transaction to have a non-zero pending notice amount
    client.post("/api/transactions", headers=auth_headers(token), json={"amount": 10.01})
    # Schedule notice
    r = client.post("/api/notifications/pre-debit/schedule", headers=auth_headers(token))
    assert r.status_code == 200
    # Send notice
    r = client.post("/api/notifications/pre-debit/send", headers=auth_headers(token))
    assert r.status_code == 200
    # Events list
    r = client.get("/api/events", headers=auth_headers(token))
    assert r.status_code == 200
    assert len(r.get_json()) >= 2
    # Ledger CSV export works
    r = client.get("/api/ledger/export", headers=auth_headers(token))
    assert r.status_code == 200
    assert r.headers["Content-Type"].startswith("text/csv")


def test_roundups_list_filters(client):
    token = register_and_login(client)
    client.post("/api/transactions", headers=auth_headers(token), json={"amount": 25})
    # pending list
    r = client.get("/api/roundups?status=pending", headers=auth_headers(token))
    assert r.status_code == 200
    assert len(r.get_json()) >= 1
    # Create mandate and execute to move to invested
    client.post("/api/mandates", headers=auth_headers(token))
    client.post("/api/investments/execute", headers=auth_headers(token))
    r = client.get("/api/roundups?status=invested", headers=auth_headers(token))
    assert r.status_code == 200
    assert len(r.get_json()) >= 1
