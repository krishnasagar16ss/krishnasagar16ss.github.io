-- ALZA ORG Training & Development Academy
-- Applied to ALZA TMC Manager Supabase project.
-- This creates only academy_* objects; TMC tables are untouched.
create table if not exists public.academy_profiles (
 user_id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null default '',
 role text not null default 'associate' check(role in ('owner','admin','trainer','associate')),
 company text, branch text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.academy_courses (
 id uuid primary key default gen_random_uuid(), title text not null, description text not null default '',
 category text not null default 'Foundation', career_stage text not null default 'All levels',
 estimated_minutes integer not null default 30 check(estimated_minutes>0), published boolean not null default false,
 created_by uuid references auth.users(id) on delete set null, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.academy_lessons (
 id uuid primary key default gen_random_uuid(), course_id uuid not null references public.academy_courses(id) on delete cascade,
 title text not null, content text not null default '', lesson_order integer not null default 1,
 requires_quiz boolean not null default false, quiz_question text, quiz_options jsonb not null default '[]'::jsonb,
 correct_option integer, created_at timestamptz not null default now(), unique(course_id,lesson_order),
 check(not requires_quiz or (quiz_question is not null and jsonb_array_length(quiz_options)>=2 and correct_option is not null))
);
create table if not exists public.academy_enrollments (
 id uuid primary key default gen_random_uuid(), course_id uuid not null references public.academy_courses(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade, enrolled_at timestamptz not null default now(), unique(course_id,user_id)
);
create table if not exists public.academy_lesson_progress (
 id uuid primary key default gen_random_uuid(), lesson_id uuid not null references public.academy_lessons(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade, completed_at timestamptz, quiz_passed boolean not null default false,
 updated_at timestamptz not null default now(), unique(lesson_id,user_id)
);
create table if not exists public.academy_quiz_attempts (
 id uuid primary key default gen_random_uuid(), lesson_id uuid not null references public.academy_lessons(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade, selected_option integer not null,
 is_correct boolean not null, attempted_at timestamptz not null default now()
);
create index if not exists academy_lessons_course_order_idx on public.academy_lessons(course_id,lesson_order);
create index if not exists academy_enrollments_user_idx on public.academy_enrollments(user_id);
create index if not exists academy_progress_user_idx on public.academy_lesson_progress(user_id);
create or replace function public.academy_is_staff() returns boolean language sql stable security invoker set search_path='' as $$
 select exists(select 1 from public.academy_profiles p where p.user_id=(select auth.uid()) and p.role in ('owner','admin','trainer'));
$$;
create or replace function public.academy_is_admin() returns boolean language sql stable security invoker set search_path='' as $$
 select exists(select 1 from public.academy_profiles p where p.user_id=(select auth.uid()) and p.role in ('owner','admin'));
$$;
create or replace function public.academy_create_profile() returns trigger language plpgsql security definer set search_path='' as $$
begin
 insert into public.academy_profiles(user_id,full_name,role) values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),'associate') on conflict(user_id) do nothing;
 return new;
end; $$;
drop trigger if exists academy_auth_user_created on auth.users;
create trigger academy_auth_user_created after insert on auth.users for each row execute function public.academy_create_profile();
alter table public.academy_profiles enable row level security;
alter table public.academy_courses enable row level security;
alter table public.academy_lessons enable row level security;
alter table public.academy_enrollments enable row level security;
alter table public.academy_lesson_progress enable row level security;
alter table public.academy_quiz_attempts enable row level security;
drop policy if exists "academy profile read self or staff" on public.academy_profiles;
create policy "academy profile read self or staff" on public.academy_profiles for select to authenticated using(user_id=(select auth.uid()) or public.academy_is_staff());
drop policy if exists "academy profile update self" on public.academy_profiles;
create policy "academy profile update self" on public.academy_profiles for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()) and role=(select p.role from public.academy_profiles p where p.user_id=(select auth.uid())));
drop policy if exists "academy admin manage profiles" on public.academy_profiles;
create policy "academy admin manage profiles" on public.academy_profiles for all to authenticated using(public.academy_is_admin()) with check(public.academy_is_admin());
drop policy if exists "academy course read" on public.academy_courses;
create policy "academy course read" on public.academy_courses for select to authenticated using(published or public.academy_is_staff());
drop policy if exists "academy staff create courses" on public.academy_courses;
create policy "academy staff create courses" on public.academy_courses for insert to authenticated with check(public.academy_is_staff() and created_by=(select auth.uid()));
drop policy if exists "academy staff update courses" on public.academy_courses;
create policy "academy staff update courses" on public.academy_courses for update to authenticated using(public.academy_is_staff()) with check(public.academy_is_staff());
drop policy if exists "academy staff delete courses" on public.academy_courses;
create policy "academy staff delete courses" on public.academy_courses for delete to authenticated using(public.academy_is_admin());
drop policy if exists "academy lesson read" on public.academy_lessons;
create policy "academy lesson read" on public.academy_lessons for select to authenticated using(public.academy_is_staff() or exists(select 1 from public.academy_courses c where c.id=course_id and c.published));
drop policy if exists "academy staff manage lessons" on public.academy_lessons;
create policy "academy staff manage lessons" on public.academy_lessons for all to authenticated using(public.academy_is_staff()) with check(public.academy_is_staff());
drop policy if exists "academy enrollment read" on public.academy_enrollments;
create policy "academy enrollment read" on public.academy_enrollments for select to authenticated using(user_id=(select auth.uid()) or public.academy_is_staff());
drop policy if exists "academy self enroll" on public.academy_enrollments;
create policy "academy self enroll" on public.academy_enrollments for insert to authenticated with check(user_id=(select auth.uid()) and exists(select 1 from public.academy_courses c where c.id=course_id and c.published));
drop policy if exists "academy staff manage enrollments" on public.academy_enrollments;
create policy "academy staff manage enrollments" on public.academy_enrollments for all to authenticated using(public.academy_is_staff()) with check(public.academy_is_staff());
drop policy if exists "academy progress read own or staff" on public.academy_lesson_progress;
create policy "academy progress read own or staff" on public.academy_lesson_progress for select to authenticated using(user_id=(select auth.uid()) or public.academy_is_staff());
drop policy if exists "academy progress self insert" on public.academy_lesson_progress;
create policy "academy progress self insert" on public.academy_lesson_progress for insert to authenticated with check(user_id=(select auth.uid()));
drop policy if exists "academy progress self update" on public.academy_lesson_progress;
create policy "academy progress self update" on public.academy_lesson_progress for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
drop policy if exists "academy attempts read own or staff" on public.academy_quiz_attempts;
create policy "academy attempts read own or staff" on public.academy_quiz_attempts for select to authenticated using(user_id=(select auth.uid()) or public.academy_is_staff());
drop policy if exists "academy attempts insert own" on public.academy_quiz_attempts;
create policy "academy attempts insert own" on public.academy_quiz_attempts for insert to authenticated with check(user_id=(select auth.uid()));
grant usage on schema public to authenticated;
grant select,insert,update,delete on public.academy_profiles,public.academy_courses,public.academy_lessons,public.academy_enrollments,public.academy_lesson_progress to authenticated;
grant select,insert on public.academy_quiz_attempts to authenticated;
