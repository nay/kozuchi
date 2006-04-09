/*-- user --*/

delete from users;
insert into users (id, login_id, login_password, name, email_address)
           values (1, 'test', 'test', 'testUser', null);

/*-- account --*/
delete from accounts;

insert into accounts (id, user_id, name, account_type)
              values (1, 1, '現金', 1);
insert into accounts (id, user_id, name, account_type)
              values (2, 1, '食費', 2);
insert into accounts (id, user_id, name, account_type)
              values (3, 1, '報酬', 3);
                         
