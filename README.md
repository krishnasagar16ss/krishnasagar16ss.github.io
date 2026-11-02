# ALZA ORG Training & Development Academy

Standalone responsive internal learning portal.

## Included
- Email/password account creation and sign-in
- Associate, Trainer, Admin and Owner roles
- Course catalogue, course enrolment and lesson management
- Sequential lesson unlocking
- Optional multiple-choice knowledge checks
- Learner progress tracking and admin role management

## Database
The `academy_*` schema has been applied to the ALZA TMC Manager Supabase project. It is isolated from the existing TMC tables. New registrations default to Associate.

After creating and confirming your own account, promote it to Owner in Supabase SQL Editor:

```sql
update public.academy_profiles p
set role = 'owner', updated_at = now()
from auth.users u
where p.user_id = u.id
  and lower(u.email) = lower('YOUR-OWNER-EMAIL@example.com');
```

The Owner can then assign Trainer and Admin roles from People & Access.

## GitHub Pages
Repository: `krishnasagar16ss/krishnasagar16ss.github.io`

In GitHub: Settings → Pages → Deploy from a branch → `main` → `/(root)`.

Expected site URL: https://krishnasagar16ss.github.io/

Configure Supabase Auth email confirmation and the GitHub Pages URL in the Supabase Auth URL configuration.
