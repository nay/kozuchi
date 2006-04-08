/* --- accounts --- */
drop table if exists accounts;
create table accounts (
  id integer not null primary key autoincrement,
  name varchar (32) not null,
  account_type integer not null
);

/* --- deals --- */
drop table if exists deals;
create table deals (
  id integer not null primary key autoincrement,
  date date not null,
  summary varchar (64) not null
);

/* --- account_entries -- */
drop table if exists account_entries;
create table account_entries (
  id integer not null primary key autoincrement,
  account_id integer not null,
  deal_id integer not null,
  amount integer not null,
  foreign key (account_id) references accounts,
  foreign key (deal_id) references deals 
);

