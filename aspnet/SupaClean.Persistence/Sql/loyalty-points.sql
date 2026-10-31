-- Loyalty points: run once in the Supabase SQL editor (safe to run again).
-- Adds a discount column to Orders (default 0, so older code keeps working)
-- and a table that records every change to a customer's points.

alter table app."Orders"
    add column if not exists "PointsDiscount" numeric(10,2) not null default 0;

create table if not exists app."PointsTransactions" (
    "PointsTransactionId" uuid primary key,
    "CustomerId"          uuid not null references app."Customers"("CustomerId") on delete cascade,
    "OrderId"             uuid null references app."Orders"("OrderId") on delete set null,
    "Kind"                varchar(20) not null,
    "Points"              integer not null,
    "Description"         varchar(200) not null,
    "CreatedAt"           timestamp with time zone not null
);

create index if not exists "IX_PointsTransactions_CustomerId" on app."PointsTransactions" ("CustomerId");
create index if not exists "IX_PointsTransactions_OrderId_Kind" on app."PointsTransactions" ("OrderId", "Kind");

-- Same protection as the other tables: only the server (not the public API keys) can read it.
alter table app."PointsTransactions" enable row level security;
