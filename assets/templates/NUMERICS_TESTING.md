# Numerics testing reference

How TDD works when the expected output cannot be written down before implementing — the oracle problem of numerical development. Read by the plan phase (every numerical task MUST name its oracle type and tolerance) and by the TDD loop. The critic enforces it at both gates.

## The oracle taxonomy

Every numerical behavior is tested against ONE of five oracle types. The plan names the type; the RED test asserts against it.

| Oracle | When | Example (3 lines) |
|---|---|---|
| **Analytic special case** | a closed-form solution exists for restricted inputs | Heat equation on a rod with sinusoidal IC has an exact series solution; assert the solver matches it to `rtol=1e-9` at t=0.1. |
| **Manufactured solution** | no closed form — so choose the answer first | Pick u(x)=sin(x)·e^{-t}, derive the forcing term f that makes u exact, run the solver with f, assert u recovered. Works for ANY PDE/ODE solver. |
| **Property / metamorphic** | exact values unknown, but relations must hold | Energy conservation: ‖E(t)−E(0)‖ ≤ tol; symmetry: solve(P·A·Pᵀ) == P·solve(A); scaling: f(2x) == 2·f(x) for linear f. Use Hypothesis (`hypothesis.extra.numpy`) to generate inputs; shrinking gives minimal counterexamples. |
| **Reference implementation** | a trusted slower/older implementation exists | Compare the new O(n log n) transform against the O(n²) direct sum on random inputs, `rtol=1e-12`; or against SciPy/mpmath at higher precision. |
| **Convergence order** | discretization methods | Halve h three times; assert the observed order log2(e_h/e_{h/2}) matches the theoretical order within 0.2. Catches silent first-order regressions in second-order schemes. |

**Property obligation:** every numerical FR names at least one property/metamorphic relation (invariance, conservation, monotonicity, symmetry, scaling) in addition to its primary oracle — properties catch what point-checks miss.

## Tolerance rules

- Every tolerance is justified in one line: conditioning, accumulation length, dtype — "`rtol=1e-9`: double precision, ~1e3 ops, cond(A) ≤ 1e4" — not copied from another test.
- **Named stop condition: "tolerance chosen to make the test pass".** If a failing test is fixed by loosening the tolerance, STOP — that is a red flag, not a fix. Either derive why the looser bound is correct (write the derivation into the test comment) or treat the failure as a real bug.
- Exact float equality (`==`, `assertEqual` on floats) is allowed ONLY for bit-exactness requirements explicitly stated in an NFR.

## Honest RED (feature-flag protocol)

A numerical behavior change goes behind a temporary toggle so the failing baseline is provable: with the flag off, the new test must FAIL against the old behavior (RED verified for the right reason); flip the flag for GREEN; remove the flag in REFACTOR. This catches the classic "test is green because it compares the new code to itself".

## Reproducibility

- Stochastic tests pin their seed. A flaky numerical test is a bug, not weather.
- The quant-verify gate's `run-manifest.md` records: commit SHA, seed set, platform (OS/arch), BLAS/library versions, thread count, input-data hashes. A PASS without a manifest is not re-executable and does not count as `verified`.
- Deterministic oracles use **pass^k** acceptance: ALL seeds in the manifest must pass. **pass@k** (any seed passes) is reserved for explicitly statistical requirements and must be declared as such in the NFR.

## Beyond the gate (options, not machinery)

For ill-conditioning vs wrong-tolerance diagnosis: stochastic-arithmetic tools (Verificarlo, Verrou) perturb rounding to measure significant digits; Herbie suggests more stable formulations; `mpmath`/Arb provide high-precision reference oracles. Declare as an NFR ("≥ N significant digits under random rounding") when the project needs it.
