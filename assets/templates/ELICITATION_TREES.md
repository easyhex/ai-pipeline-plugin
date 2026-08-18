# Coverage-tree templates

Starting trees for the elicitation coverage state (`docs/superpowers/elicitation/<SLUG>-state.md` — see `ELICITATION.md`). The interview's first round picks a variant (❓ with a ➡️ recommendation inferred from the project); the tree is then instantiated into the state file and pruned/extended per feature. Slots are `[ ]` Unexplored / `[x]` Confirmed / `[~]` Rejected.

## Variant: generic

```markdown
## Aspect: Purpose & users
- Dimension: users — [ ] who uses this · [ ] what they do with it · [ ] what "done well" looks like to them
- Dimension: scenarios — [ ] top 2-3 flows · [ ] the flow that must never break
## Aspect: Functional scope
- Dimension: core — [ ] inputs · [ ] outputs · [ ] state kept
- Dimension: boundaries — [ ] explicitly out of scope · [ ] adjacent features touched
## Aspect: Non-functional (forced round — never skip)
- Dimension: performance — [ ] latency/throughput envelope · [ ] data scale
- Dimension: reliability — [ ] failure behavior · [ ] recovery expectations
- Dimension: security — [ ] authn/authz needs · [ ] sensitive data
## Aspect: Delivery
- Dimension: constraints — [ ] deadline/stakes · [ ] platform limits
```

## Variant: numerics (math-intensive systems)

```markdown
## Aspect: Mathematical model
- Dimension: problem — [ ] formulation (equations, domains) · [ ] known failure regimes (stiffness, ill-conditioning, boundaries)
- Dimension: method — [ ] algorithm candidates · [ ] stability/complexity constraints
## Aspect: Correctness & precision (forced round — never skip)
- Dimension: tolerances — [ ] target error WITH units (abs/rel, against what) · [ ] tolerance justification
- Dimension: oracles — [ ] analytic special cases · [ ] reference implementation/data · [ ] properties (conservation, symmetry, monotonicity) · [ ] convergence expectations
## Aspect: Data & scale
- Dimension: inputs — [ ] sizes/shapes/dtypes · [ ] pathological inputs (singular, degenerate, NaN/Inf policy)
- Dimension: performance — [ ] time/memory budget at target problem sizes · [ ] hardware (GPU/SIMD/threads)
## Aspect: Reproducibility
- Dimension: determinism — [ ] bit-exact vs statistical · [ ] seeds/RNG policy · [ ] platform sensitivity (BLAS, FMA, reduction order)
```
