USE MASTER
declare
@isql varchar(2000),
@dbname varchar(64)

declare c1 cursor for select name from master..sysdatabases where name not in ('master','model','msdb','tempdb','ReportServer','ReportServerTempDB')
open c1
fetch next from c1 into @dbname
While @@fetch_status <> -1
    begin
	
    select @isql = 'ALTER DATABASE @dbname SET RECOVERY SIMPLE'
    select @isql = replace(@isql,'@dbname',@dbname)
    print @isql
    exec(@isql)

    select @isql='USE @dbname; DBCC SHRINKFILE (N''@dbname_log'' , 0, TRUNCATEONLY)'
    select @isql = replace(@isql,'@dbname',@dbname)
    print @isql
    exec(@isql)

    fetch next from c1 into @dbname
    end
close c1
deallocate c1