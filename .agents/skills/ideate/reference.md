# /ideate — reference

## Why the Lean Canvas boxes are asked in that order

The nine boxes form a dependency graph, not a checklist. Asking them out of
order forces the user to guess at answers they haven't given yet:

| box | depends on |
|---|---|
| Existing Alternatives | Problem |
| Unique Value Proposition | Customer Segments + Problem |
| Solution | Problem |
| Unfair Advantage | UVP + Solution |
| Channels | Customer Segments |
| Revenue Streams | Customer Segments + UVP |
| Key Metrics | Solution + Revenue Streams |

Customer Segments and Problem are the roots and open round 1. Success shape
and Constraints depend on nothing and ride along in the same round.

This is the same frontier discipline `gated-doc-interview` applies generally —
the canvas just makes the graph explicit.

## Why prose loses to the nine boxes

Writing `IDEA.md` as flat prose drops the structure, and `/validate` then has
to re-derive it to sharpen Problem, Customer Segments, UVP and Solution into
a PRD. The boxes are the interface between the two commands.

## "None yet" and "not applicable" are real answers

Unfair Advantage and Revenue Streams are the least-validated boxes at
ideation, by construction. Forcing a confident answer manufactures a claim
nobody tested, and `/validate`'s Risks section then treats it as a premise
rather than the riskiest assumption. Record the honest gap; that gap is
exactly what `/validate` is for.
