# Observability and Operational Diagnostics

## Logging
- Use structured JSON logs for all services.
- Required fields: `timestamp`, `service`, `request_id`, `user_key_id`, `model`, `latency_ms`, `status_code`, `error_class`.
- Redact prompt content by default; enable sampled debug capture only under incident policy.

## Request tracing
- Edge generates `X-Request-ID` if absent.
- Propagate request ID: proxy -> LiteLLM -> model backend.
- Include request ID in error responses for support correlation.

## Model usage visibility
- Track per-model:
  - request count
  - input/output tokens
  - latency p50/p95/p99
  - error rate
- Track per-user-key consumption for fairness and chargeback readiness.

## GPU utilization visibility
- Collect `nvidia-smi` samples (utilization, memory, temperature, power).
- Alert on sustained >95% memory utilization and thermal throttling.

## API auditability
- Log key lifecycle events (create/revoke/rotate).
- Log auth failures and rate-limit events with source identity.
- Retain audit logs with immutable daily snapshots.

## Request metrics
- Minimum metrics:
  - `http_requests_total`
  - `http_request_duration_ms`
  - `inference_queue_depth`
  - `model_inference_duration_ms`
  - `rate_limit_drops_total`

## Failure diagnostics runbook
1. Confirm edge health and cert validity.
2. Check LiteLLM readiness and backend model reachability.
3. Inspect recent 5xx grouped by `error_class` and `model`.
4. Check GPU memory pressure and active request concurrency.
5. Apply mitigation: reduce per-key concurrency, cap max tokens, restart failed backend.
