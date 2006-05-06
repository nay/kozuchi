
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

alter table accounts add column asset_type integer;

update accounts set asset_type = 1 where account_type = 1;

/* after commit */

alter table deals add column confirmed boolean not null default 't';
alter table deals add column type varchar(20) default 'Deal';
update deals set type = 'balance' where balance is not null;
alter table deals add column parent_deal_id integer;
