You are given a short message/snippet (often from a product policy, Terms of Service, or Privacy Policy). Your task is to assess and label the user risk conveyed by that message.

Goal:
- Read the message and determine whether it presents High Risk or Low Risk to users.
- Prioritize catching High Risk even when information is ambiguous. Optimize for recall of High Risk (avoid false negatives).

Output format (exactly):
High Risk
or
Low Risk

Decision rules:
- Default to High Risk when ambiguous or when risky phrases appear without strong, explicit safeguards.
- If both risky and mitigating elements are present, prefer the worst-case outcome unless mitigations are specific, verifiable, and directly address the risk.

High Risk indicators (non-exhaustive; any one can be enough):
- Training on user content or data that may include personal information (e.g., “we train on recordings/transcriptions” even if “de-identified” is claimed). Note: “de-identified” alone does not eliminate risk; if any PI may be included or inferred, treat as High Risk.
- Broad, perpetual, irrevocable, sublicensable, or transferable licenses to user content; assignment of rights; “we own,” “we may use your content for any purpose.”
- Sale, sharing for value, or broad sharing of personal data with third parties; targeted advertising; cross-context behavioral advertising; data brokerage language.
- Unilateral rights to change terms or privacy policy at any time, with immediate effect and/or without prior notice; “continued use constitutes acceptance.”
- Indefinite data retention; lack of deletion rights; combining data across services; profiling without clear opt-out.
- Collection or processing of sensitive data (e.g., biometrics/voiceprints, health, precise geolocation, children’s data) without strong, explicit protections or opt-in.
- Cross-border transfers without safeguards; “may share with partners” or “service providers” in vague terms; onward use for “research” or “service improvement” without clear limits.
- Manual/human review of user content, especially when tied to model training or lacking strict access controls and consent boundaries.

Low Risk indicators (examples):
- Security best practices that reduce risk: audit trails of admin changes, role-based access control, MFA, encryption, least privilege, logging/monitoring.
- Transparency about protections with specific limits and controls (e.g., explicit opt-in, strict purpose limitation, narrow data use, short retention, clear deletion capabilities), with no conflicting risky language.
- Operational/feature statements that do not expand data use, user obligations, or diminish user rights.

Reasoning guidance:
- Be concise and point to the exact risky or mitigating phrases.
- Do not provide legal advice or suggest policy changes; only assess risk in the given text.
- When in doubt due to vague wording or missing details, label as High Risk.

Examples alignment:
- “We provide an audit trail of admin changes to org settings.” → Low Risk
- “We reserve the right to change these Terms and this Privacy Policy at any time with immediate effect and without prior notice; continued use constitutes acceptance.” → High Risk
- “We train our AI on de-identified audio and transcriptions that may contain personal information; we obtain permission for manual review of specific audio.” → High Risk

