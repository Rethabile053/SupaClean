# SupaClean Laundry & Dry-Cleaning Management System

**Enterprise Digital Platform for Modern Laundry Operations**

[](https://flutter.dev)
[](https://dotnet.microsoft.com)
[](https://supabase.com)

*Group M | WIL 2026*

---

##  Overview

SupaClean transforms traditional laundry operations through an integrated digital ecosystem, replacing manual paper tickets with real-time tracking and centralized management.

---

##  Key Features

| Feature | Description |
| --- | --- |
|  **Mobile App** | Browse services, submit orders, track status in real-time |
|  **Web Dashboard** | Manage orders, customers, and staff operations |
|  **Cloud Backend** | Centralized Supabase/PostgreSQL database |
|  **Role-Based Access** | Customer, Staff, Driver, and Admin portals |
|  **Real-Time Updates** | Push notifications and live order tracking |

---

## 🛠️ Tech Stack

| Layer | Technology |
| --- | --- |
| Mobile | Flutter 3.19+ |
| Web | ASP.NET Core 8 Blazor |
| Database | Supabase (PostgreSQL) |
| Auth | Supabase Auth with JWT |

---

##  Quick Start

### Prerequisites

- Flutter SDK 3.19+
- .NET SDK 8.0+
- Visual Studio 2022 / VS Code
- Supabase account

### Mobile App (Flutter)

```bash
git clone https://github.com/your-org/supaclean.git
cd supaclean/flutter/supaclean_app
flutter pub get
flutter run -d chrome --web-port 5050  if using Chrome
flutter run    if using an emulator.
```

### Web App (ASP.NET)

```bash
cd aspnet
dotnet restore
dotnet build
dotnet run --project src/SupaClean.Blazor
```

Access at: `https://localhost:7001`

---

## Configuration

Create `.env` or use user secrets:

```env
SUPABASE_URL=your_project_url
SUPABASE_ANON_KEY=your_anon_key
```

---

## Project Structure

```
supaclean/
├── flutter/supaclean_app/    # Mobile app
├── aspnet/                   # Web app
│   └── SupaClean.sln
├── supabase/                 # Database migrations
└── docs/                     # Documentation
```

---



## License

MIT License — Copyright © 2026 Group M

---

(#supaclean-laundry--dry-cleaning-management-system)**

 *Star this repo if you find it helpful!*

Development Team (Group M) — Central University of Technology
Name     	Student Number
 
Masendeke CP	224043099

Mahlangu P	224014647

Maleke KT	222009259

Maema KE	224079714

Mojakwe KB	223032987

Moretlwe RK	221012635

Dasheka T	219007064

Leeu FD	223044569

Ntlati TT	224081629

Stallenberg BC	224081442
