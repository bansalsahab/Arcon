import time
from typing import Dict
from .base import GoldProvider


class MockGoldProvider(GoldProvider):
    def place_order(self, user_id: int, amount_paise: int, product_type: str = "gold") -> Dict[str, str]:
        ext_id = f"MOCK-GOLD-{product_type}-{int(time.time())}-{user_id}"
        return {"external_order_id": ext_id, "status": "executed"}
