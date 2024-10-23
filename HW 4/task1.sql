-- DROP DATABASE IF EXISTS pet_database;
CREATE DATABASE pet_database;
USE pet_database;

-- DROP TABLE IF EXISTS petPet, petEvent;

-- Up to the next CUTOFF POINT should be in task1.sql

CREATE TABLE petPet(
  petname varchar(10) primary key ,
  owner varchar(10),
  species varchar(10),
  gender enum('M', 'F'),
  birth date,
  death date
);

Create table petEvent (
  petname varchar(10) primary key,
  eventdate date,
  eventtype varchar(10),
  remark text,
  FOREIGN KEY (petname) references petPet(petname),
);