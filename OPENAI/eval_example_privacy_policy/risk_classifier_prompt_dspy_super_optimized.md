You will be given a single sentence or short passage, typically excerpted from a privacy policy, terms of service, or similar document. Your task is to assess the privacy/compliance risk signaled by that specific text alone and output exactly one field:

- exactly one of "Low Risk" or "High Risk" (case-sensitive).

Evaluation rules:
- Evaluate the text as written. Do not penalize it for topics it does not mention unless the text itself introduces a risky practice.
- Favor clear, affirmative compliance/user-protective statements as Low Risk.
- Flag statements that authorize broad, intrusive, or non-standard data uses as High Risk.

High Risk indicators (flag as High Risk when present in the text):
- Monitoring or accessing user communications/content: e.g., “we may read or listen to your communications,” “manual review of stored content,” “monitor messages.” This is intrusive even if stated “for compliance.”
- Model training on customer/user content without clear opt-in.
- Broad/perpetual licenses over user content: e.g., “perpetual, irrevocable, royalty-free, sublicensable license … for any purpose.”
- Selling or sharing personal data for advertising or data brokerage: e.g., “we sell your data,” “share with third parties for targeted ads.”
- Language that negates security or user rights, or permits unrestricted onward use inconsistent with user expectations.

Low Risk indicators (treat as Low Risk when these are the main signals and no High Risk signals appear):
- Children’s data protection: e.g., “not directed to children under 13/16/18,” “we delete if discovered.”
- International transfers with approved safeguards: e.g., Standard Contractual Clauses (SCCs), EU adequacy decisions, Data Privacy Framework (DPF).
- Processor/enterprise carveouts: statements that public privacy policy doesn’t apply to data processed on behalf of enterprise customers and that such data is governed by separate agreements/DPAs.
- Security/compliance/user rights language: references to security features, SAML/SSO, domain capture, data retention/deletion policies, DSARs/user rights, purpose limitation.
- Limited, standard collection for service operation/security with user control: e.g., determining general area from IP for security/product improvement; optional precise location via user choice.

Guidance from examples:
- “We may read or listen to your communications and manually review stored content …” → High Risk (intrusive manual review of communications).
- “We may determine the general area from your IP … Some Services allow you to choose to provide precise location (GPS).” → Low Risk (standard use with user choice).
- “Enterprise plan includes SAML, Domain Capture, Data Retention Policy to auto-delete data …” → Low Risk (security and deletion features).

## Output format (strict)
Only return one of the two exact strings:  
- High Risk
- Low Risk

Do not include any extra fields, formatting, or commentary.