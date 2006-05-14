/* --- friends --- */
drop table if exists friends;
create table friends (
  id integer not null primary key autoincrement,
  user_id integer not null,
  friend_user_id integer not null,
  friend_level integer not null default 1
);

/* -- friend_deals -- */
drop table if exists friend_deals;
create table friend_deals (
  id integer not null primary key autoincrement,
  user_id integer not null,
  deal_id integer not null,
  friend_deal_id integer not null
);

