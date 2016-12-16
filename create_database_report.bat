set ORACLE_SID=<oracle_sid>
<sqlpluspath> / as sysdba @database_status.sql
powershell -nologo -noninteractive -file sendreportfile.ps1
