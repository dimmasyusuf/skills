# EOD Composition Rules

Write in the user's lowercase voice. The report should feel like a direct daily update from the user, not a generated status report.

## Output Shape

Use this skeleton:

```text
<weekday, day month>

done:
<one chronological paragraph>

tomorrow
- <next item>
- <next item>
- <next item>

ai:
<news>
<source url>
```

Do not add a separate `blockers:` section. If a blocker affects tomorrow, include it as a `tomorrow` item.

## Done Section

Write `done:` as a heading on its own line, followed by one paragraph on the next line:

```text
done:
in the morning ... by the afternoon ... later in the day ...
```

Do not insert blank lines inside `done:`.

Mention time naturally inside the prose when the source data supports it, using phrases like:

- in the morning
- by the afternoon
- later in the day
- toward the evening

Do not use time-of-day labels such as `morning:`, `afternoon:`, or `evening:`.

Use one paragraph for both sparse and dense days. For dense days, make the paragraph longer but keep it readable by moving chronologically through the day.

When there are several work categories, weave them into the chronological paragraph instead of creating sub-section labels. Each meaningful PR or issue should still be covered with:

- what changed
- why it mattered
- verification or current status
- PR/issue number when known

If exact times are unknown, use broad time language only when it is defensible from source order, commit times, session times, calendar events, or message timestamps. Otherwise write chronological prose without forcing a time phrase.

## Tomorrow Section

Use the heading exactly as `tomorrow`, with no colon. Use dash-prefixed action items:

```text
tomorrow
- merge the approved product workflow changes
- follow up on the gmail sync review
- run one clean verification pass before handoff
```

Include verified approvals as merge/follow-up tasks. If there are real blockers, phrase them as concrete next actions rather than creating a separate blockers section.

## AI Section

Use `ai:` with the news on the next line and the source URL on the line after that:

```text
ai:
<one current AI or developer-tooling news sentence>
<url>
```

Exactly one current AI or developer-tooling item, verified as published today.

## Link Formatting

Use masked Markdown links for work URLs:

```text
[#1234](https://github.com/example-org/example-app/issues/1234)
[PR #5678](https://github.com/example-org/example-app/pull/5678)
[spec](https://example.com/spec)
```

The AI source line is the only bare URL exception:

```text
ai:
openai published a developer tooling update relevant to agent workflows.
https://openai.com/blog/
```

Do not wrap the AI source as `[source](url)`. For GitHub issues and PRs, prefer short labels like `[#1234]` or `[PR #5678]`. For documents, specs, and changelogs outside the `ai:` section, use a readable label such as `[spec]` or `[changelog]`.

## Voice Rules

- lowercase headings and prose.
- no hype.
- no meta-commentary about tools.
- no em dashes.
- no "i used the ai agent to..." unless the agent itself is the work being reported.
- keep technical names exact, using inline backticks for identifiers.
- be honest about partial work.

## Punctuation

Use plain hyphens, commas, and periods. Avoid decorative separators.
