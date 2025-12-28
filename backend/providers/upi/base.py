from typing import Dict, Optional
from datetime import date


class UPIProvider:
    def create_mandate(
        self,
        *,
        user_id: int,
        max_amount_paise: int,
        frequency: str,
        start_date: date,
        end_date: Optional[date],
        internal_mandate_id: int,
    ) -> Dict[str, str]:
        raise NotImplementedError

    def pause_mandate(self, external_mandate_id: str) -> Dict[str, str]:
        raise NotImplementedError

    def resume_mandate(self, external_mandate_id: str) -> Dict[str, str]:
        raise NotImplementedError

    def cancel_mandate(self, external_mandate_id: str) -> Dict[str, str]:
        raise NotImplementedError

    def confirm_mandate(self, external_mandate_id: str, otp: str) -> Dict[str, str]:
        raise NotImplementedError
