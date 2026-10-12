-- Host is sharing a screen (slides/image/video): the app shows the video uncropped.
alter table public.live_sessions
  add column if not exists screen_sharing boolean not null default false;
