require 'sqlite3'

 db = SQLite3::Database.new "db/address_bloc.sqlite"

 db.execute("DROP TABLE address_book;");
 db.execute("DROP TABLE entry;");
 db.execute("DROP TABLE address;");

 db.execute <<-SQL
     CREATE TABLE address_book (
       id INTEGER PRIMARY KEY,
       name VARCHAR(30)
     );
   SQL

 db.execute <<-SQL
     CREATE TABLE entry (
       id INTEGER PRIMARY KEY,
       address_book_id INTEGER,
       name VARCHAR(30),
       phone_number VARCHAR(30),
       email VARCHAR(30),
       FOREIGN KEY (address_book_id) REFERENCES address_book(id)
     );
   SQL

   db.execute <<-SQL
       CREATE TABLE address (
         id INTEGER PRIMARY KEY,
         address_book_id INTEGER,
         entry_id INTEGER,
         address VARCHAR(30),
         FOREIGN KEY (address_book_id) REFERENCES address_book(id),
         FOREIGN KEY (entry_id) REFERENCES entry(id)
       );
     SQL
