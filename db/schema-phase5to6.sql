/* --- friends --- */
drop table if exists friends;
create table friends (
  id integer not null primary key autoincrement,
  user_id integer not null,
  friend_user_id integer not null,
  friend_level integer not null default 1
);
