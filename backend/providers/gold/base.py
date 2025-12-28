from typing import Dict


class GoldProvider:
    def place_order(self, user_id: int, amount_paise: int, product_type: str = "gold") -> Dict[str, str]:
        """
        Place a digital gold investment order.
        Return keys: external_order_id (str), status ("pending"|"executed"|"failed").
        """
        raise NotImplementedError
