-- Migration number: 0000 	 2023-04-09T08:43:57.483Z
-- Autogenerated by Superflare. Do not edit this file directly.
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  createdAt DATETIME NOT NULL,
  updatedAt DATETIME NOT NULL
);