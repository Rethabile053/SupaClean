# SupaClean Laundry & Dry-Cleaning Management System

Official repository for the SupaClean Laundry and Dry-Cleaning Management System (Group M, WIL 2026). It holds the source code, project documentation, architecture specs and system models for the Flutter, ASP.NET Core and Supabase solution.

## Project overview

SupaClean currently relies on physical pickup/drop-off points and a manual paper ticket/docket system. This project introduces an integrated digital platform consisting of:

- **Mobile application (Flutter):** lets customers browse services, submit orders, select pickup depots and receive order updates. Lets authorised staff, drivers and management oversee orders, manage customer data and update item statuses.
- **Web application (ASP.NET Core):** web version of the system.
- **Backend & database (Supabase / PostgreSQL):** a centralised database providing real-time data sync, secure authentication and relational storage across web and mobile.

## Repository structure

```
SupaClean/
├── flutter/supaclean_app/   Flutter mobile app (MVVM)
├── aspnet/                  ASP.NET Core web app (not started)
├── supabase/                Database migrations and config (not started)
├── docs/                    SRS, feasibility, system models, API/schema planning
├── .github/                 Pull request template
└── CONTRIBUTING.md          Branching and commit rules — read before contributing
```

## Tech stack

| Component | Technology | Role |
| --- | --- | --- |
| Mobile client | Flutter (Dart) | Mobile version of the system |
| Web client | ASP.NET Core MVC / Web API | Customer order submission, status tracking, notifications, management dashboard, order tracking and status administration |
| Backend & DB | Supabase (PostgreSQL & Auth) | Data persistence, authentication and system communication |
| External APIs | Google Maps API | Depot location mapping |

## Key features (in-scope MVP)

- **Multi-depot support:** management across the central facility and local pickup/drop-off depots.
- **Expanded catalogue:** laundry, dry-cleaning and specialised services (e.g. carpet cleaning).
- **Order tracking & communication:** direct status updates and customer notifications.
- **Docket cross-referencing:** manual ticket-number linking to maintain continuity with existing operations.

## Getting started (mobile app)

```bash
cd flutter/supaclean_app
flutter pub get
flutter run
```

## Contributing

All work happens on `feature/*` branches and is merged into `develop` through a pull request. `main` only receives reviewed PRs from `develop`. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Development team (Group M) — Central University of Technology

| Name | Student number |
| --- | --- |
| Masendeke CP | 224043099 |
| Mahlangu P | 224014647 |
| Maleke KT | 222009*** |
| Maema KE | 224079714 |
| Mojakwe KB | 223032987 |
| Moretlwe RK | 221012635 |
| Dasheka T | 219007064 |
| Leeu FD | 223044569 |
| Ntlati TT | 224081629 |
| Stallenberg BC | 224081442 |
