# Test Scenarios

This document describes the unit tests in `django_app/auth_app/tests/test_auth.py` and the behavior each scenario validates.

## How to run

```bash
cd django_app
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python manage.py test auth_app.tests -v 2
```

## Scenario matrix

| ID | Scenario | Test class | Expected result |
|----|----------|------------|-----------------|
| S1 | Public health check | `HealthViewTests` | `GET /health/` returns `200` and `{"status":"ok"}` without authentication |
| S2 | Anonymous access blocked | `ProtectedViewTests` | `GET /api/profile/` redirects to `/oidc/authenticate/` |
| S3 | Non-admin blocked from admin route | `ProtectedViewTests` | Authenticated non-staff user gets redirected from `/api/admin-only/` |
| S4 | Admin route for staff | `ProtectedViewTests` | Staff user receives `200` and admin welcome message |
| S5 | User provisioning from Keycloak | `KeycloakBackendTests` | OIDC claims create Django user with username, email, and names |
| S6 | Admin role mapping | `KeycloakBackendTests` | Keycloak `admin` realm role sets `user.is_staff = True` |
| S7 | Profile sync on update | `KeycloakBackendTests` | Existing Django user fields update when Keycloak claims change |
| S8 | OIDC login redirect | `OIDCFlowTests` | `GET /oidc/authenticate/` redirects browser to Keycloak authorization endpoint |
| S9 | Authenticated profile API | `OIDCFlowTests` | Logged-in user receives JSON profile including roles from session |

## Manual integration scenarios (Docker)

After running `./start.sh`:

| ID | Steps | Expected result |
|----|-------|-----------------|
| M1 | Open `http://localhost:8000/` while logged out | Home page shows **Login with Keycloak** |
| M2 | Click login, authenticate as `demo` / `demo` | Redirect back to Django; home shows signed-in username |
| M3 | Open `http://localhost:8000/api/profile/` | JSON includes `demo@example.com`, `is_staff: false` |
| M4 | Logout, login as `admin` / `admin` | Profile shows `is_staff: true`; `/api/admin-only/` returns welcome message |
| M5 | Open Keycloak admin at `http://localhost:8080/admin/` | Login with `admin` / `admin`; realm `tutorial` and client `django-app` exist |

## Notes

- Unit tests mock OIDC endpoints so they run without Keycloak.
- Integration scenarios require both Docker Compose stacks and the shared network created by `start.sh`.
