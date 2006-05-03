/* --- users --- */
drop table if exists users;
create table users (
  id integer not null primary key autoincrement,
  login_id varchar (16) not null unique,
  hashed_password char (40) not null
);

/* --- rules --- */
drop table if exists rules;
create table rules (
  id integer not null primary key autoincrement,
  user_id integer not null,
  name varchar (32) not null,
  associated_account_id integer not null,
  closing_day integer not null,
  payment_term_months integer not null,
  payment_day integer not null
);

/* --- accounts --- */
drop table if exists accounts;
create table accounts (
  id integer not null primary key autoincrement,
  user_id integer not null,
  rule_id integer,
  name varchar (32) not null,
  account_type integer not null,
  asset_type integer,
  sort_key integer,
  foreign key (user_id) references users,
  foreign key (rule_id) references rules
);

/* --- deals --- */
drop table if exists deals;
create table deals (
  id integer not null primary key autoincrement,
  user_id integer not null,
  date date not null,
  daily_seq integer not null,
  summary varchar (64) not null,
  foreign key (user_id) references users
);

/* --- account_entries -- */
drop table if exists account_entries;
create table account_entries (
  id integer not null primary key autoincrement,
  user_id integer not null,
  account_id integer not null,
  deal_id integer not null,
  amount integer not null,
  balance integer,
  is_plan boolean not null,
  foreign key (account_id) references accounts,
  foreign key (deal_id) references deals, 
  foreign key (user_id) references users
);
