from flask import current_app
from typing import Optional

from .upi.base import UPIProvider
from .upi.mock import MockUPIProvider
from .mf.base import MFProvider
from .mf.mock import MockMFProvider
from .gold.base import GoldProvider
from .gold.mock import MockGoldProvider

_upi: Optional[UPIProvider] = None
_mf: Optional[MFProvider] = None
_gold: Optional[GoldProvider] = None


def get_upi_provider() -> UPIProvider:
    global _upi
    if _upi is not None:
        return _upi
    name = (current_app.config.get("UPI_PROVIDER") or "mock").lower()
    if name == "razorpay":
        from .upi.razorpay import RazorpayUPIProvider
        _upi = RazorpayUPIProvider()
    elif name == "mock":
        _upi = MockUPIProvider()
    else:
        # Fallback to mock for unknown providers
        _upi = MockUPIProvider()
    return _upi


def get_mf_provider() -> MFProvider:
    global _mf
    if _mf is not None:
        return _mf
    name = (current_app.config.get("MF_PROVIDER") or "mock").lower()
    if name == "mock":
        _mf = MockMFProvider()
    else:
        _mf = MockMFProvider()
    return _mf


def get_gold_provider() -> GoldProvider:
    global _gold
    if _gold is not None:
        return _gold
    name = (current_app.config.get("GOLD_PROVIDER") or "mock").lower()
    if name == "mock":
        _gold = MockGoldProvider()
    else:
        _gold = MockGoldProvider()
    return _gold
