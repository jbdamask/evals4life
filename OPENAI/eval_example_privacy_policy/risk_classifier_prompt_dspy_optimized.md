Task: Given a single message (typically a clause or sentence from a privacy policy, terms, or security documentation), determine the privacy risk conveyed by that message.

## Output
Only return one of the two exact strings:  
- High Risk
- Low Risk

General approach:
- Judge the risk of the described practice in the provided message itself, not the overall organization or policy.
- Base your decision only on what is explicitly stated or clearly implied by the message. Do not speculate beyond the text.
- If a message contains both protective/compliance language and an explicitly risky practice, classify as High Risk (explicit invasive practices outweigh safeguards).

High Risk cues (any one of these typically makes it High Risk):
- Monitoring/reading/listening to user communications or manual review of stored content (surveillance of private communications).
- Sale or sharing of personal data with third parties for advertising, marketing, cross-context behavioral advertising, or profiling.
- Training AI/models on customer data or user-generated content, unless it clearly states opt-in or strong safeguards (model-training-on-customer-data is a strong high-risk cue).
- Broad, perpetual, irrevocable, royalty-free, sublicensable licenses to user content or data.
- Combining data across products/services or with third-party data for profiling/ads without clear limits.
- Collection/use of sensitive data (e.g., precise location, biometrics, health, financial) for non-essential purposes or without clear safeguards.
- Indefinite/unlimited data retention or unclear retention with no limits.
- Sharing with data brokers or unspecified “partners” for their own purposes.
- International data transfers without mention of safeguards or legality.

Low Risk cues (generally Low Risk when not paired with risky practices):
- Security and compliance language: encryption, access controls, SOC 2/ISO 27001, incident response, data minimization, purpose limitation.
- Regulatory and rights language: DSAR (access/deletion/correction/portability), user consent/opt-in, retention limits, clear lawful bases.
- Transparency/contacts: providing Data Protection Officer (DPO) contact details, privacy inquiry emails.
- Vendor management: requiring subprocessors to notify data incidents, assist with investigations, or adhere to security/privacy obligations.
- Cross-border transfer safeguards: SCCs, EU-U.S. Data Privacy Framework (DPF), similar mechanisms.
- Statements that only describe protections, compliance steps, or standard operational processing by service providers on behalf of the controller.
- Aggregate/de-identified data use that does not re-identify individuals.

Disambiguation rules:
- Generic “we use data to improve our services” without mention of advertising, sale, or model training on customer content: Low Risk.
- If any explicit risky behavior is stated (e.g., reading messages, selling data, training on customer content), choose High Risk even if safeguards are mentioned.
- If the message is solely about safeguards, compliance, user rights, contacts, or vendor requirements (e.g., incident notifications), choose Low Risk.

## Output
Only return one of the two exact strings:  
- High Risk
- Low Risk