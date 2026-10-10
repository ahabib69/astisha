# ASTISHA — Messaging App

ASTISHA is a responsive messaging-interface project inspired by the supplied visual reference: midnight surfaces, indigo accents, a three-column desktop chat layout, and a contact-detail pane. The name and branding are original. The current build intentionally separates an explicitly labeled local demo from the optional Supabase integration; demo messages are not sent to another person.

## Project status (honest)

- **Implemented:** responsive React/TypeScript client, conversation list, search/filter, selected conversation, message composer (Enter sends; Shift+Enter newline), local in-memory demo messages, dark/light preference toggle (in-memory), details pane, accessible labels on key controls, modal shells, and Supabase email/password auth calls when environment variables are configured.
- **Sample/demo only:** displayed contacts and existing message history are illustrative in-memory data. A new sent message appears only in the current browser session. Contacts, green presence, sample profile details, and shared media are not live data and are not claims about actual users.
- **Calls:** a WebRTC voice/video calling flow is implemented using Supabase private Realtime Broadcast for offer/answer/ICE signaling, browser microphone/camera permissions, mute/camera controls, and a copyable invite link. It requires a configured Supabase project, signed-in users on both browsers, the call-signaling migration, and devices with media capability. It has not been exercised between two accounts in this environment.
- **Not implemented:** end-to-end encryption, media upload/storage, live presence, working user discovery, trusted conversation provisioning, unread/read receipts, call invitation tied to actual ASTISHA contacts, push notifications, message persistence, two-account realtime delivery, account recovery, and deployed hosting. Some controls explicitly explain their limitation.
- **Backend:** Supabase client and a starter SQL migration are included, but no project URL or credentials were supplied. Real authentication/database/realtime is therefore **not configured or verified**. The SQL migration intentionally does not provide browser-side membership creation; a trusted server-side function must be built before secure private-conversation creation is possible.

## Requirements

- Node.js 20 LTS or newer recommended (Node 18.18+ may work with current Vite).
- npm.
- Optional: a Supabase project for the included authentication starter.

## Windows setup

Extract the project ZIP, open PowerShell in the extracted `astisha` directory, then:

```powershell
Copy-Item .env.example .env.local
npm install
npm run dev
```

Open the URL Vite prints (normally `http://localhost:5173`). To build and preview:

```powershell
npm run typecheck
npm run build
npm run preview
```

The app runs in demo mode when Supabase variables are absent. Demo state resets on reload.

## Optional Supabase configuration

1. Create a Supabase project and configure Auth email provider, site URL, and redirect URLs for local and production domains.
2. Copy `.env.example` to `.env.local` and replace placeholders with the **project URL** and **public anon/publishable key**. Never use a service-role key in browser environment variables.
3. Apply `supabase/migrations/001_initial.sql` through the SQL editor or Supabase CLI after reviewing it. Do not apply blindly to a production database.
4. Enable Realtime for the `messages` table in Supabase Database > Publications.
5. Implement and security-test a trusted Edge Function/RPC for profile provisioning and conversation creation plus participant insertion. The current migration deliberately denies client insertion into participants; otherwise a user could add themselves to a private conversation.
6. Build the data-access layer and replace illustrative data with persisted database queries and authorized realtime subscriptions. This is required before describing the product as a working real-time messaging service.
7. Apply `supabase/migrations/002_realtime_call_signaling.sql`; ensure the Supabase Realtime service permits private channels. Both call participants need authenticated sessions in this Supabase project. Voice/video controls then create a random UUID call room; the caller copies and securely shares its invite URL, and the recipient opens that URL in a second signed-in browser. Browser permission prompts are required. The UUID link is a bearer capability: anyone possessing it and an account in the project can attempt to join. The signaling policies allow authenticated clients to send/receive in UUID-shaped call topics, not only contacts. Strengthen admission using a server-created call room and verified conversation-participant checks before production.
8. The current ICE server list contains Google STUN only. STUN can establish many peer-to-peer paths, but restrictive NAT/firewalls require a TURN relay. Configure a reputable TURN provider and add its credentials to the RTCPeerConnection `iceServers` list for reliable connectivity. TURN usage can incur cost. Do not treat this as guaranteed connectivity or end-to-end encryption.

The current UI invokes Supabase Auth for sign-in and sign-up if configured. Email confirmation may be required according to project Auth settings. The authentication UI does not yet connect app contacts/messages to Supabase tables.

## Data model / security notes

The migration defines profiles, conversations, participants, and messages with foreign keys, constraints, indexes, and RLS. RLS is enabled. Membership reads and message reads/writes check conversation membership; senders must match `auth.uid()`. Profile directory visibility is currently for authenticated accounts only; consider limiting searchable profile fields or using a server search function before public deployment. Conversation creation policy alone does not establish membership. Use a server-controlled provisioning function that validates both users and handles duplicate direct conversations atomically. SQL policies are a starter and have **not been executed or independently security-tested** in a Supabase project. No end-to-end encryption is implemented; transport/storage protections depend on configured infrastructure.

## Testing

```powershell
npm run typecheck
npm run build
```

Manual verification still required: real signup/login/session persistence, email recovery, multi-user authorization, profile policies, membership-creation function, two-account realtime delivery, message pagination, file authorization, network recovery, and the requested viewport targets (320, 375, 390, 430, 768, 1024, 1440px). No automated behavioral test suite is currently included.

## Deployment

Build with `npm run build` and deploy the generated `dist/` directory to a static host (e.g. Cloudflare Pages, Netlify, or Vercel). Configure the two `VITE_SUPABASE_*` variables through the hosting provider's environment-variable interface if using Supabase, and add the production URL to Supabase Auth redirect settings. These public client values are not secrets, but RLS and authorization are essential. Free-tier quotas and suspension/storage limits vary by provider and can change; review current provider terms. No deployment has been performed.

## Structure

```text
src/App.tsx              Main UI and demo state
src/styles.css           Responsive visual system
src/main.tsx             React entry
supabase/migrations/     Starter schema and RLS
.env.example             Placeholder public client configuration
```
