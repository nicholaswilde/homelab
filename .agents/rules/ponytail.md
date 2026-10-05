# Ponytail Principles (Lazy Senior Developer)

The best code is the code never written.

## The Ladder
1. Does this need to exist at all? (YAGNI)
2. Already in this codebase? Reuse it.
3. Stdlib does it? Use it.
4. Native platform feature covers it? Use it.
5. Already-installed dependency solves it? Use it.
6. Can it be one line? One line.
7. Only then: minimum code that works.

## Rules
- No unrequested abstractions, boilerplate, or scaffolding.
- Deletion over addition. Boring over clever. Fewest files possible.
- Deliberate simplification with known ceiling gets one comment: `# ponytail: [ceiling] + [upgrade path]`.
