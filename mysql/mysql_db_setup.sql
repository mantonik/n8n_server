create user 'n8nusr'@'%' identified by 'Rfvgtdswe!df543554';

create database db_n8n;

grant all  on db_n8n.* to 'n8nusr'@'%';

CREATE TABLE `db_n8n`.`p_test` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `trx_date` DATETIME default now(),
  `msg` VARCHAR(200) NULL,
  PRIMARY KEY (`id`));

CREATE TABLE `db_n8n`.`p_test` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `trx_date` DATETIME default now(),
  `msg` VARCHAR(200) NULL,
  PRIMARY KEY (`id`));
  
  
SELECT *  FROM db_n8n.p_test;
SELECT count(*) FROM db_n8n.p_test;

insert into db_n8n.p_test (trx_date,msg) values (now(), 'test');

insert into db_n8n.p_test (msg) values ( 'test');


SELECT max(id) FROM db_n8n.p_test where trx_date < date_add(now(), interval -30 minute)



