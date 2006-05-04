
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

alter table accounts add column asset_type integer;
alter table accounts add column rule_id integer default null;
alter table deals add column undecided boolean not null default 'f';

update accounts set asset_type = 1 where account_type = 1;

