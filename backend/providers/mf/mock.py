import time
from typing import Dict
from .base import MFProvider


class MockMFProvider(MFProvider):
    def place_order(self, user_id: int, amount_paise: int, product_type: str = "mf") -> Dict[str, str]:
        ext_id = f"MOCK-MF-{product_type}-{int(time.time())}-{user_id}"
        return {"external_order_id": ext_id, "status": "executed"}
