# Lab Guide — Swift Actors & Structured Concurrency

> **How to use this guide**
> Each section ends with a *checkpoint* — a question or small task you should be able to answer on your own before
> moving on. Resist the urge to look things up immediately. Sit with the problem for a few minutes first. The friction is
> the learning.

---

## Part 1 — Modeling the Domain (No Concurrency Yet)

Before introducing actors, build the plain data model.

### 1.1 The `Transaction` type

You need a type to represent the result of a transfer attempt. It should carry:

- A unique identifier (an `Int` is fine)
- The amount involved
- An outcome — either success, or failure with a reason string

> **Design question:** Should this be a `struct` or a `class`? Think about value semantics vs. reference semantics. If
> two parts of your program hold a reference to the same `Transaction`, can one silently mutate what the other sees?

> **Checkpoint 1.1** — What is `Sendable` in Swift? Before looking it up, try to reason about it: if you were designing
> a type system rule that prevented data races at compile time, what would you need to enforce about types that cross task
> boundaries? Then check your reasoning against the Swift docs.

### 1.2 The `LedgerError` type

You need a custom `Error` type to represent a failed withdrawal due to insufficient funds. It should carry enough
information to produce a readable message (available balance, requested amount).

Use an `enum` with associated values. Conform it to `CustomStringConvertible` so printing it gives a human-readable
message.

---

## Part 2 — Your First Actor

### 2.1 Write `BankAccount` as a plain `class` first

Before using `actor`, deliberately write `BankAccount` as a regular `class` with:

- A `let owner: String`
- A `var balance: Double`
- A `deposit(_ amount: Double)` method
- A `withdraw(_ amount: Double) throws` method

Now write a quick test in `main.swift`: launch 10 concurrent tasks (use `Task { }`) that each call `withdraw(50)` on the
same instance.

> **Checkpoint 2.1** — Enable strict concurrency checking by adding this flag to your target in `Package.swift`:
> ```swift
> swiftSettings: [.unsafeFlags(["-strict-concurrency=complete"])]
> ```
> What warnings or errors appear? Can you reproduce an actual data race by running the program multiple times? What does
> that tell you about the `class` approach?

### 2.2 Convert to `actor`

Change the `class` keyword to `actor`. Read the new compiler errors carefully.

> **Checkpoint 3.2** — Answer these without running the code first, then verify:
> 1. Can you read `balance` from outside the actor without `await`? Why or why not?
> 2. Can you call `deposit()` from inside the actor synchronously? What about from outside?
> 3. What does the actor *guarantee* that a manually locked class did not?

### 2.3 The `nonisolated` keyword

Add a `describe() -> String` method that returns a formatted description string — something like
`"BankAccount(owner: Alice)"`.

Try calling it without `await` from `main.swift`. It likely won't compile.

Now add the `nonisolated` keyword to the method. Two questions to answer:

1. Why does this now compile without `await`?
2. What happens if you try to read `balance` inside a `nonisolated` method? Try it.

> **Checkpoint 2.3** — When is `nonisolated` appropriate? What is the rule the compiler is enforcing?

---

## Part 3 — A Second Actor (Cross-Actor Calls)

### 3.1 Write `TransactionLog`

Create a second actor that:

- Holds a private array of `Transaction` values
- Has a `record(_ tx: Transaction)` method
- Exposes computed properties: `count`, `successCount`, `failureCount`
- Exposes a `var all: [Transaction]` to retrieve a snapshot

> **Checkpoint 4.1** — You are about to call `log.record(tx)` from inside the `transferFunds` function, which itself
> runs inside a `Task`. Reason through this before writing it:
> - How many actor isolation domains are involved in a single transfer?
> - Where do the `await` keywords need to go, and why?
> - What does "crossing an actor boundary" actually mean at runtime?

### 3.2 The Sendable check

Try passing a non-`Sendable` type into `log.record()`. The easiest way: create a small
`class NoteAttachment { var text = "" }` and add it as a property on `Transaction`.

> **Checkpoint 3.2** — What compiler error do you get? What does this tell you about what `Sendable` is actually
> enforcing? What would happen at runtime if the compiler *didn't* catch this?

---

## Part 4 — Structured Concurrency

### 4.1 The `transferFunds` function

Write a `func transferFunds(amount:from:to:log:id:) async` function that:

1. Attempts to withdraw from the source account
2. If successful, deposits into the destination account
3. Records the outcome (success or failure) in the log
4. Handles the `LedgerError` gracefully

> **Design question before writing:** This function calls methods on two separate actors. Is the withdrawal + deposit
> atomic? What does that imply for a production system? There's no right answer — think about what a "coordinating actor"
> pattern would look like if you needed true atomicity.

### 4.2 Launch concurrent transfers with `withTaskGroup`

In `main.swift`, launch 10 concurrent transfers using `withTaskGroup`. Each task should call your `transferFunds`
function.

> **Checkpoint 4.2** — Reason through what `withTaskGroup` gives you:
> - When does `withTaskGroup` return relative to its child tasks?
> - What is the difference between `withTaskGroup` and just firing 10 unstructured `Task { }` calls?
> - What guarantees does structured concurrency make that unstructured concurrency does not?

### 4.3 Read the final state

After `withTaskGroup` returns, read `alice.balance`, `bob.balance`, `log.count`, and `log.all` to print a summary.

> **Checkpoint 4.3** — Why do these reads require `await` even though no writes are happening concurrently at this
> point? Is the `await` here about *safety*, *scheduling*, or both?

---

## Part 5 — Experiments

These are deliberate break-it-to-learn-it exercises. Don't skip them.

**Experiment A — Provoke a failure**
Set Alice's initial balance to `$300` and attempt 10 transfers of `$50`. What happens to the log? Are the failure
messages readable? Is the final balance correct?

**Experiment B — Remove `actor`, keep the Tasks**
Change `BankAccount` back to a `class`. Run the program 20 times. Do you ever get a wrong balance? Does it crash? This
is what "undefined behavior under data races" looks like in practice.

**Experiment C — Force a Sendable violation**
Add a mutable reference type to `Transaction` and observe the compiler error. Then mark it `@unchecked Sendable` and
reason about whether you've actually made it safe or just silenced the warning.

**Experiment D — Atomicity**
Add a deliberate `try await Task.sleep(nanoseconds: 1_000_000)` between the `withdraw` and `deposit` calls inside
`transferFunds`. What could go wrong in theory? Does it in practice with 10 tasks? Think about what a "coordinating
actor" pattern would look like if you needed true atomicity.

---

## Further Reading

Once you're comfortable with the basics, the natural next steps are:

- **`@MainActor`** — a global actor for UI work; understanding it unlocks SwiftUI's concurrency model
- **`GlobalActor`** — define your own app-wide singleton isolation domains
- **`AsyncStream` / `AsyncSequence`** — async producer/consumer patterns built into the standard library
- **Distributed actors** — actors that can live on different machines (experimental)

The Swift Evolution proposals are unusually readable. SE-0306 (actors) and SE-0302 (Sendable) are worth reading as
primary sources.