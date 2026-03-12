# Verification Checklist

## Claim validation

1. Does each key claim include at least one source link?
2. Is each source link on the learn.microsoft.com domain?
3. Is service/API version context explicit when relevant?
4. Is confidence label present with rationale?
5. Is each link specific enough to verify the claim directly?

## Consistency checks

1. Are there conflicting claims across modules?
2. Are deprecated terms or features used?
3. Are unsupported assumptions clearly marked?

## Fail actions

- Mark artifact as Not Ready.
- Replace unverifiable claims with uncertainty statement.
- Emit targeted verification tasks.
- Remove any links outside learn.microsoft.com.
