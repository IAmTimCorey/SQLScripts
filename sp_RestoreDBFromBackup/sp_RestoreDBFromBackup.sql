use master
go

/* 
	Created By: Epicross (www.epicross.com)
	Date: August 18, 2014
	Purpose: Take a backup file and restore it to a new location
	Inputs:
		@newDBName: The name for your restored database (ex: AdvWks)
		@oldDBName: The name of your original database (ex: AdventureWorks2012)
		@BackupFileFQName: The fully qualified name of your backup file (ex: C:\Temp\advwks.bak)
		@mdfFilePath: The path where you want your MDF files to go (ex: C:\Temp\)
		@ldfFilePath: The path where you want your LDF files to go (ex: C:\Temp\)
		@ndfFilePath: The path where you want your NDF files to go (ex: C:\Temp\)
	Notes: This process overwrites the destination database. BE VERY CAREFUL NOT TO USE
		   THIS IN PRODUCTION! Use this only to restore your backups to a development or
		   testing location.
*/
-- Creates the procedure if it does not exist. This way we never drop it and lose the
-- attached permissions.
if not exists (select * from sys.objects where type = 'P' AND name = 'sp_RestoreDBFromBackup')
begin
   exec('create procedure [dbo].[sp_RestoreDBFromBackup] as begin set nocount on; end')
end
go
alter procedure [dbo].[sp_RestoreDBFromBackup]
  @newDBName varchar(128),
  @oldDBName varchar(128),
  @BackupFileFQName varchar(255),
  @mdfFilePath varchar(1000),
  @ldfFilePath varchar(1000),
  @ndfFilePath varchar(1000)
as
begin
  declare 
    @execSQL nvarchar(1000),
    @moveSQL nvarchar(4000),
    @replaceText nvarchar(50),
    @tempText nvarchar(1000),
    @logicalName varchar(100)

  -- This is used to identify if the database needs to be replaced or not
  set @replaceText = ''   
  if exists (select name from sys.databases where name = @newDBName)
    set @replaceText = ', REPLACE'

  -- Drops the temp table if it already exists
  if OBJECT_ID('tempdb..#FileList') IS NOT NULL
    begin
      drop table #FileList
    end

	-- Sets up a temp table to hold the list of files from the backup
  create table #FileList (
    LogicalName          nvarchar(128),
    PhysicalName         nvarchar(260),
    [Type]               char(1),
    FileGroupName        nvarchar(128),
    Size                 numeric(20,0),
    MaxSize              numeric(20,0),
    FileID               bigint,
    CreateLSN            numeric(25,0),
    DropLSN              numeric(25,0),
    UniqueID             uniqueidentifier,
    ReadOnlyLSN          numeric(25,0),
    ReadWriteLSN         numeric(25,0),
    BackupSizeInBytes    bigint,
    SourceBlockSize      int,
    FileGroupID          int,
    LogGroupGUID         uniqueidentifier,
    DifferentialBaseLSN  numeric(25,0),
    DifferentialBaseGUID uniqueidentifier,
    IsReadOnl            bit,
    IsPresent            bit,
    TDEThumbprint        varbinary(32)
  )

	-- Brings in a list of all of the files in the backup into our temp table
  insert into #FileList exec ('RESTORE FILELISTONLY from DISK = ''' + @BackupFileFQName + '''')

	-- Sets a cursor up to loop over every row in the temp table
  declare curFileLIst cursor for 
    select 'MOVE N''' + LogicalName + ''' TO N''' + replace(PhysicalName, @oldDBName, @newDBName) + ''''
    from #FileList

  set @moveSQL = ''

	-- Loops through each row and creates the proper move statement
  open curFileList 
    fetch next from curFileList into @tempText
    while @@Fetch_Status = 0
      begin
	    select @logicalName = substring(@tempText, 8, charindex('''', substring(@tempText, 8, len(@tempText)))-1)
	    if (right(@tempText, 4) = 'mdf''')
	      begin
		      select @tempText = substring(@tempText, 0, charindex(' TO N''', @tempText)+6) + @mdfFilePath + @logicalName + '.mdf'''
	      end
	    if (right(@tempText, 4) = 'ndf''')
	      begin
		      select @tempText = substring(@tempText, 0, charindex(' TO N''', @tempText)+6) + @ndfFilePath + @logicalName + '.ndf'''
	      end
	    if (right(@tempText, 4) = 'ldf''')
	      begin
		      select @tempText = substring(@tempText, 0, charindex(' TO N''', @tempText)+6) + @ldfFilePath + @logicalName + '.ldf'''
	      end
      set @moveSQL = @moveSQL + @tempText + ', '
      fetch next from curFileList into @tempText
      end
  close curFileList
  deallocate curFileList

  print 'Killing active connections to the "' + @newDBName + '" database'

  -- Create the sql to kill the active database connections
  set @execSQL = ''
  select @execSQL = @execSQL + 'kill ' + convert(char(10), spid) + ' '
  from master.dbo.sysprocesses
  where db_name(dbid) = @newDBName AND DBID <> 0 AND spid <> @@spid

	exec (@execSQL)

	-- Restores the database
  set @execSQL = 'RESTORE DATABASE [' + @newDBName + ']'
  set @execSQL = @execSQL + ' from DISK = ''' + @BackupFileFQName + ''''
  set @execSQL = @execSQL + ' WITH FILE = 1,'
  set @execSQL = @execSQL + @moveSQL
  set @execSQL = @execSQL + ' NOREWIND, '
  set @execSQL = @execSQL + ' NOUNLOAD '
  set @execSQL = @execSQL + @replaceText
	
	exec sp_executesql @execSQL
end

