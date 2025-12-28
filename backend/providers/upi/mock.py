import time
from typing import Dict
from .base import UPIProvider


class MockUPIProvider(UPIProvider):
    def create_mandate(
        self,
        *,
        user_id: int,
        max_amount_paise: int,
        frequency: str,
        start_date,
        end_date,
        internal_mandate_id: int,
    ) -> Dict[str, str]:
        ext_id = f"MOCK-UPI-{int(time.time())}-{user_id}-{internal_mandate_id}"
        # In a real provider, status might be 'pending' until user approves in UPI app.
        return {
            "external_mandate_id": ext_id,
            "status": "active",
            "auth_link": f"https://mock-upi.local/mandate/{ext_id}",
            "max_amount_paise": max_amount_paise,
            "frequency": frequency,
        }

    def pause_mandate(self, external_mandate_id: str) -> Dict[str, str]:
        return {"external_mandate_id": external_mandate_id, "status": "paused"}

    def resume_mandate(self, external_mandate_id: str) -> Dict[str, str]:
        return {"external_mandate_id": external_mandate_id, "status": "active"}

    def cancel_mandate(self, external_mandate_id: str) -> Dict[str, str]:
        return {"external_mandate_id": external_mandate_id, "status": "cancelled"}

    def confirm_mandate(self, external_mandate_id: str, otp: str) -> Dict[str, str]:
        # Mock: instantly activate irrespective of OTP value
        return {"external_mandate_id": external_mandate_id, "status": "active"}
