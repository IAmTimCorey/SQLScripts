# SQL Scripts

Some of the SQL scripts that we have developed to make our lives and the lives of our customers easier.

## Included Scripts

### sp_helptext2

A utility script that upgrades the built-in sp_helptext. If you put in a partial name, the script searches for that text in object names. If you put in a table name, you get information about the columns, indexes and constraints of that table. If you put in a view or stored procedure name, it gives you a properly-formatted create statement for that object.

### sp_RestoreDBFromBackup

A utility to restore a database from a backup file. The restored database can be renamed and the associated files can be moved during this process as well. If the database exists, it will be overwritten. This script is typically used for testing backups and for creating/restoring a test environment.