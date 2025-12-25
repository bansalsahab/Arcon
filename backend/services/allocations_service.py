from typing import Dict

RISK_ALLOCATIONS: Dict[str, Dict[str, int]] = {
    "low": {"mf_debt": 70, "mf_equity": 20, "gold": 10},
    "medium": {"mf_debt": 40, "mf_equity": 50, "gold": 10},
    "high": {"mf_debt": 20, "mf_equity": 70, "gold": 10},
}


def get_allocation_for_tier(tier: str) -> Dict[str, int]:
    return RISK_ALLOCATIONS.get(tier or "medium", RISK_ALLOCATIONS["medium"]) 
