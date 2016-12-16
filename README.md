# OracleDBDailyCheckScripts
Oracle DB 12c Daily Check Scripts for Windows

# Preparations
Settings

In create_database_report.bat
- `set ORACLE_SID=<oracle_sid>` Oracle SID
- `<sqlpluspath> / as sysdba @database_status.sql` SQLPlus and database_status.sql path
- `powershell -nologo -noninteractive -file sendreportfile.ps1` sendreportfile.ps1 path

In database_status.sql
- `spool <outputpath>` Output Html file path

In sendreportfile.ps1
- `$MessageContent = [Io.File]::ReadAllText("<outputpath>", [System.Text.Encoding]::Default)` Output Html file path (The same as `<outputpath>` in database_status.sql)
- `Send-MailMessage -to "<rcpts>" -from "<sender>" -Subject "DBA Checks (<servername>)[<serverip>] " -smtpserver <mailserverip> -Body $MessageContent -BodyAsHtml -Encoding ([System.Text.Encoding]::UTF8)`
  - `<rcpts>` for report rcpts
  - `<sender>` for report sender
  - `<servername>` for Oracle DB server name
  - `<serverip>` for Oracle DB IP
  - `<mailserverip>` for Mail server IP
  
  # Usage
  
  execute `create_database_report.bat`
