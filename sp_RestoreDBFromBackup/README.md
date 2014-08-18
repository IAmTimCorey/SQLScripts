# sp_RestoreDBFromBackup

> Restore a backup automatically

## Script Purpose

This script takes a .bak file and restores it to your database. This restore can either overwrite an existing database or it can create a new database. The two primary uses for this script are to test a backup automatically and to create/restore a test environment.

**Warning**: This script will overwrite a database. Do not use in production unless you are certain of what you are doing.

## Getting Started

To run this script, you will need six pieces of information:

- `@newDBName` - the name to call the restored database
- `@oldDBName` - the name of the database that was backed up
- `@BackupFileFQName` - the fully qualified file name of the backup
- `@mdfFilePath` - the location where you want to put the mdf file for the restored database (including trailing slash)
- `@ldfFilePath` - the location where you want to put the ldf file for the restored database (including trailing slash)
- `@ndfFilePath` - the location where you want to put the ndf files for the restored database (including trailing slash)

You will also need to be sure that SQL has access to the folder where the backup file is located.

## Example

Using the AdventureWorks2012 database from Microsoft, let's take a backup file from that database and restore it to a new database. Here is an example of what this command would look like:

```sql
exec dbo.sp_RestoreDBFromBackup 'AdvWks','AdventureWorks2012', 'c:\Temp\AdventureWorks2012.bak','c:\temp\', 'c:\temp\', 'c:\temp\'
```

Note that this puts all three file types (mdf, ldf and ndf) in the same directory. Each could get their own directory as well. Just be sure to put that trailing slash on the end of the path. Also note that instead of keeping the same name for the database, this will rename the database instance (but not the associated files). If the `AdvWks` database already exists, it will be overwritten by this process.