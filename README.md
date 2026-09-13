# Scrub Prep

**Be ready for surgery.**

Scrub Prep is an iOS app for third- and fourth-year medical students on their surgery clerkship. A student enters or dictates a case ("Lap chole for acute cholecystitis") and gets a concise, student-level preparation session, then can be quizzed on it via **Pimp Me** (adaptive oral questioning) or **Rapid Fire** (5 quick high-yield questions before scrubbing in).

Created by Edward Bender, MD, a retired cardiothoracic surgeon and former Clinical Professor of Cardiothoracic Surgery at Stanford University. Scrub Prep is an independent educational application and is not affiliated with or endorsed by Stanford University.

## Repo layout

```
backend/   Back4App Cloud Code (Parse Server) — all OpenAI calls happen here
ios/       SwiftUI client (added in a later phase)
```

## Backend

See [`backend/README.md`](backend/README.md) for setup, environment variables, running tests, and deploying to Back4App.

## Status

- [x] Backend Cloud Code (generateScrubPrep, startPimpSession, answerPimpQuestion, generateRapidFire)
- [ ] iOS app
