from typing import Dict


class MFProvider:
    def place_order(self, user_id: int, amount_paise: int, product_type: str = "mf") -> Dict[str, str]:
        """
        Place a mutual fund investment order.
        Return keys: external_order_id (str), status ("pending"|"executed"|"failed").
        """
        raise NotImplementedError
