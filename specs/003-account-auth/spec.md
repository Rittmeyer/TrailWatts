# Feature 003: Account & Authentication

*Unifies prototype screens 01a and 01b — one screen, two modes, not two
separate specs.*

## Why

The app needs to know who's using it before storing any profile or workout
data — but account creation must never become a backdoor for importing
third-party data (Constitution Article II). Login and signup are two modes
of one screen so returning and new riders share a single entry point
instead of two disconnected flows.

## User Story

As a new rider, I want to create an account with just my name, email,
birth date, and a password, so I can start using Trailwatt without
connecting any other account. As a returning rider, I want to log in
quickly — optionally via Google, Apple, or Microsoft — so I don't have to
remember another password.

## Scope

### In scope

- Two modes on one screen, switchable without navigating away: **Entrar**
  (login) and **Criar conta** (signup).
- Login: email + password, OR OAuth with Google, Apple, or Microsoft
  (identity only — not a data import).
- Signup: name, email, birth date, password + confirmation, and explicit
  consent to the Terms of Use and Privacy Policy. Manual fields only.
- Account identity (`UserAccount`) is stored separately from fitness data
  (`RiderProfile` — Feature 004).

### Out of scope

- Any fitness/profile data collection (weight, FTP, etc.) — Feature 004.
- The password-reset flow itself (the "Esqueceu a senha?" link is shown,
  its destination is a follow-up spec).
- Any OAuth data pull beyond identity, even during signup — which is why
  signup has no OAuth option at all. OAuth is login-only, for accounts
  that separately linked a provider after manual signup.

## Functional Requirements

1. The system MUST present Login and Criar Conta as two modes of a single
   screen, switchable without a route change.
2. Login mode MUST accept email + password, or initiate OAuth with
   Google, Apple, or Microsoft.
3. Criar Conta mode MUST require name, email, birth date, password,
   confirmed password, and explicit consent to the Terms of Use and
   Privacy Policy before allowing submission.
4. Criar Conta mode MUST NOT display or offer any third-party OAuth or
   import option (Constitution Article II).
5. The system MUST validate that password and confirm-password match
   before allowing account creation.
6. On successful account creation, the system MUST route to Rider Profile
   setup (Feature 004). On successful login where a profile already
   exists, the system MUST route directly to Treino do Dia
   (Feature 006), skipping profile setup.

## Key Entities

- **UserAccount** — `id`, `name`, `email`, `birthDate`
  (`lib/models/user_account.dart`)

## Success Criteria

- A new rider completes signup using only manually entered fields — no
  network call to a third-party identity or data provider other than the
  OAuth provider's own login screen, and only in login mode.
- Switching between Entrar and Criar Conta does not leak data entered in
  the other mode.
- A returning rider with a completed profile lands on Treino do Dia, not
  Perfil, after login.

## Open Questions

- Is the password-reset destination in scope for this feature, or does it
  get its own spec once the backend auth provider is chosen?
- Should Criar Conta ever gain an OAuth path later (e.g., linking a
  provider after manual signup)? If so, does that require a constitution
  amendment, or does it already fit inside Article II's exception for
  read-scoped convenience data?
