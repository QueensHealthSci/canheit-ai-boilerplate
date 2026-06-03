# Task: [Ticket ID / Description]
**Status:** Draft
**Module:** [Target Module Name]

## 1. Goal
[One sentence summary of what we are building]

## 2. Architecture & Design
- **Pattern:** [Service / Controller / Job / Listener]
- **Data Flow:** [Brief description of how data moves]
- **New Files:**
    - [ ] `app/...`
    - [ ] `resources/...`

## 3. Security Analysis (Critical)
- [ ] **Auth:** Does this require specific Middleware/Policies?
- [ ] **Validation:** What validation rules are needed?
- [ ] **Data:** Are we handling PII or sensitive data?
- [ ] **Risk:** Is there a risk of Insecure Direct Object Reference (IDOR)?

## 4. Implementation Steps
1. [ ] **Migration:** Create/Update tables.
2. [ ] **Backend:** Service Logic & DTOs.
3. [ ] **API:** Controller & Resource.
4. [ ] **Frontend:** Components & Props.

## 5. Verification Strategy
- [ ] **Unit Test:** [What specific method to mock?]
- [ ] **Feature Test:** [Happy Path & Error Path]
- [ ] **Coverage Check:**
    - Does this touch Auth, Payments, or Security? **[YES/NO]**
    - *If YES, strict 100% coverage is MANDATORY.*
