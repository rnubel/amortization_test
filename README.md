# Observation
Given a fixed set of billing periods, and a fixed set of customer actions (draws/payments), for a particular ruleset, the resulting state -- where "state" refers to the current balances of all types of the customer's debt, e.g. principal, principal_past_due -- at any point in time is clearly deterministic. The algorithm for this is likely most sensibly implemented as a daily iteration.

> state(billing_periods, actions, t) = ...

Therefore, the only information needed to be truly kept by a line of credit application is the aforementioned information. Everything else can be calculated out and cached as needed.

However, for the sake of record-keeping, a set of books indicating the movement of money is desirable. And unlike the list of customer actions (which can be affected by returned payments, cancelled draws, etc), the books cannot be changed, only appended to. Therefore, if something happens which changes the past actions, we must correct the books. To do this, we can compute a delta between the current (old) state and the new (real) state.

> &Delta; = state(billing_periods, actions', t) - state(billing_periods, actions, t)

> books.push(&Delta;)

But, this only works in single-entry accounting. In some sense, perhaps that meets the app's responsibility -- the app doesn't necessarily need a double-entry accounting system underpinning its works. But somewhere, perhaps in a separate accounting system, we will need an alternate method of reconciliation which presents a consistent, continuous record of transactions.

Consider the state &sigma;0, right before the now-returned transaction happened, and the states &sigma;1 and &sigma;2, representing the original record of events and the new record of events. The problem is to find a path of transactions between &sigma;1 and &sigma;2. Let &sigma;1 = &sigma;0 + &Delta;1, and &sigma;2 = &sigma;0 + &Delta;2; then, &sigma;2 = &sigma;0 + &Delta;2 = &sigma;1 - &Delta;1 + &Delta;2. In other words, we cancel out all transactions after the return, and then append the transactions from the new timeline after the same point in time.
