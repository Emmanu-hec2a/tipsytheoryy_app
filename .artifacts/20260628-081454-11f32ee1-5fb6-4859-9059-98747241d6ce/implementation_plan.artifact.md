# Implementation Plan: "Iron-Clad" Payment Reconciliation Service

This plan hardens the M-Pesa STK integration to a production-grade standard, eliminating "Early/Late/Ghost" payment patterns through a unified, atomic, and idempotent architecture.

## 1. Core Principles
*   **Single Source of Truth**: All payment paths (Callback, STK Query, Manual Reconcile) will use the same `ConfirmPaymentService`.
*   **Strict Idempotency**: Use `select_for_update` database locks on `CheckoutRequestID` to prevent race conditions between Safaricom and the frontend.
*   **Resilient Atomicity**: Wrap status transitions in `transaction.atomic()`, but decouple fragile operations (notifications) into background tasks.

## 2. Proposed Changes

### Backend Utilities
#### [NEW] [payment_service.py](file:///C:/Users/PC/Desktop/tipsytheoryy/urbanfoods/payment_service.py)
Create a unified service class to handle the entire payment lifecycle:
- `process_payment_signal()`: The single entry point for all verification paths.
- `confirm_order_payment()`: Atomic logic for standard orders.
- `confirm_shiriki_contribution()`: Atomic logic for split payments with pot-overflow protection.
- `confirm_merchant_subscription()`: Atomic logic for billing.

#### [mpesa_utils.py](file:///C:/Users/PC/Desktop/tipsytheoryy/urbanfoods/mpesa_utils.py)
- Update `query_stk_status` to return structured metadata (Receipt Number, Phone, Amount) to match the Callback format, allowing the Unified Service to treat them identically.

### Backend Views & Tasks
#### [views.py](file:///C:/Users/PC/Desktop/tipsytheoryy/urbanfoods/views.py)
- Refactor `mpesa_callback` and `mpesa_stk_query` to call `ConfirmPaymentService.process_payment_signal()`.
- Remove divergent "lite" logic paths.

#### [tasks.py](file:///C:/Users/PC/Desktop/tipsytheoryy/urbanfoods/tasks.py)
- Refactor `reconcile_pending_mpesa_payments` and `retry_unmatched_callback_task` to use the new service.
- Ensure all post-payment notifications are correctly offloaded to Celery.

## 3. Verification Plan

### Automated Verification (Via Shell)
1. **Race Condition Test**: I will trigger a simulated STK Query and Callback simultaneously for the same `CheckoutRequestID` to verify that the `select_for_update` lock prevents double-processing.
2. **Failure Recovery Test**: Simulate a failed notification during payment and verify that the Order remains marked as "Paid" (proving the notifications are properly decoupled).

### Manual Verification
1. **Ghost Payment Audit**: Verify that `MpesaTransaction` records are always created even if the order logic fails.
2. **Shiriki Overflow Test**: Verify that extra money paid into a full pot correctly updates the user's `wallet_balance`.

---
**Status**: Ready for Execution. 🥂🛡️📍
