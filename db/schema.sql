/* --- users --- */
drop table if exists users;
create table users (
  id integer not null primary key autoincrement,
  login_id varchar (16) not null unique,
  hashed_password char (40) not null
);

/* --- friends --- */
drop table if exists friends;
create table friends (
  id integer not null primary key autoincrement,
  user_id integer not null,
  friend_user_id integer not null,
  friend_level integer not null default 1
);

/* --- account_rules --- */
drop table if exists account_rules;
create table account_rules (
  id integer not null primary key autoincrement,
  user_id integer not null,
  account_id integer not null,
  associated_account_id integer not null,
  closing_day integer not null default 0,
  payment_term_months integer not null default 1,
  payment_day integer not null default 0,
  foreign key (account_id) references accounts,
  foreign key (associated_account_id) references accounts
);

/* --- deal_links --*/
drop table if exists deal_links;
create table deal_links (
  id integer not null primary key autoincrement,
  created_user_id integer /* not required, just for keep sql correct*/
);

/* --- accounts --- */
drop table if exists accounts;
create table accounts (
  id integer not null primary key autoincrement,
  user_id integer not null,
  name varchar (32) not null,
  account_type integer not null,
  asset_type integer,
  sort_key integer,
  partner_account_id integer,
  foreign key (user_id) references users
);

/* --- deals --- */
drop table if exists deals;
create table deals (
  id integer not null primary key autoincrement,
  type varchar (20) not null,
  user_id integer not null,
  date date not null,
  daily_seq integer not null,
  summary varchar (64) not null,
  confirmed boolean not null default 't',
  parent_deal_id integer,
  foreign key (user_id) references users
);
/* ruby stores 'f' for false, 't' for true to sqlite3. */ 

/* --- account_entries -- */
drop table if exists account_entries;
create table account_entries (
  id integer not null primary key autoincrement,
  user_id integer not null,
  account_id integer not null,
  deal_id integer not null,
  amount integer not null,
  balance integer,
  friend_link_id integer,
  foreign key (account_id) references accounts,
  foreign key (deal_id) references deals, 
  foreign key (user_id) references users
);

/* --- user preferences -- */
drop table if exists preferences;
create table preferences (
  id integer not null primary key autoincrement,
  user_id integer not null,
  deals_scroll_height varchar(20)
);
