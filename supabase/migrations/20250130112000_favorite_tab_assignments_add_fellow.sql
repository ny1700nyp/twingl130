-- Allow 'fellow' tab in favorite_tab_assignments (Fellow tutors in the area likes).

alter table public.favorite_tab_assignments
  drop constraint if exists favorite_tab_assignments_tab_check;

alter table public.favorite_tab_assignments
  add constraint favorite_tab_assignments_tab_check
  check (tab in ('tutor', 'student', 'fellow'));

comment on table public.favorite_tab_assignments is
  'Stores which Favorite tab (tutor | student | fellow) a liked user belongs to. Syncs across devices.';
