# Observation
Given a fixed set of billing periods, and a fixed set of customer actions (draws/payments), for a particular ruleset, the resulting state -- where "state" refers to the current balances of all types of the customer's debt, e.g. principal, principal_past_due -- at any point in time is clearly deterministic. The algorithm for this is likely most sensibly implemented as a daily iteration.

> state(billing_periods, actions, t) = ...

Therefore, the only information needed to be truly kept by a line of credit application is the aforementioned information. Everything else can be calculated out and cached as needed.

However, for the sake of record-keeping, a set of books indicating the movement of money is desirable. And unlike the list of customer actions (which can be affected by returned payments, cancelled draws, etc), the books cannot be changed, only appended to. Therefore, if something happens which changes the past actions, we must correct the books. To do this, we can compute a delta between the current (old) state and the new (real) state.

> &Delta; = state(billing_periods, actions', t) - state(billing_periods, actions, t)

> books_push(&delta)
