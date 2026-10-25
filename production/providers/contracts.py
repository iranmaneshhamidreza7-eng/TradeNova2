"""Provider interfaces only. Implement against a vetted, legally available provider.
No provider is configured by this file; all live actions fail closed by default.
"""
from dataclasses import dataclass
from decimal import Decimal
from typing import Protocol

@dataclass(frozen=True)
class PaymentIntent:
    provider_reference: str
    status: str
    checkout_url: str | None = None

@dataclass(frozen=True)
class PayoutResult:
    provider_reference: str
    status: str

class PaymentProvider(Protocol):
    def create_deposit(self, *, user_id: str, amount: Decimal, currency: str, idempotency_key: str) -> PaymentIntent: ...
    def verify_webhook(self, *, headers: dict[str, str], raw_body: bytes) -> dict: ...
    def verify_payment(self, *, provider_reference: str) -> bool: ...

class CustodyProvider(Protocol):
    def create_deposit_address(self, *, user_id: str, asset: str, network: str) -> dict: ...
    def verify_webhook(self, *, headers: dict[str, str], raw_body: bytes) -> dict: ...
    def create_withdrawal(self, *, user_id: str, asset: str, network: str, amount: Decimal, address: str, idempotency_key: str) -> PayoutResult: ...

class ExchangeProvider(Protocol):
    def place_order(self, *, user_id: str, symbol: str, side: str, quantity: Decimal, client_order_id: str) -> dict: ...
    def cancel_order(self, *, user_id: str, symbol: str, client_order_id: str) -> dict: ...

class LiveModeNotConfigured(RuntimeError):
    pass

def require_live_provider(provider, *, enabled: bool):
    if not enabled or provider is None:
        raise LiveModeNotConfigured("Live provider is not configured; no real-money action was performed.")
    return provider
