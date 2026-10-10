-- WebRTC signaling over Supabase private Realtime Broadcast channels.
-- The random UUID in the invite link is a bearer call-room capability. Only authenticated
-- accounts may exchange signaling. Do not publish these links; revoke by ending the room
-- operationally / rotate by creating another room. For stronger identity-based admission,
-- wire room creation and participant invitations to authorized conversation membership.
alter table realtime.messages enable row level security;
create policy "signed-in users can receive ASTISHA call signaling" on realtime.messages
for select to authenticated
using (realtime.topic() ~ '^call:[0-9a-fA-F-]{36}$');
create policy "signed-in users can send ASTISHA call signaling" on realtime.messages
for insert to authenticated
with check (realtime.topic() ~ '^call:[0-9a-fA-F-]{36}$');
