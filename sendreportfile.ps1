$MessageContent = [Io.File]::ReadAllText("<outputpath>", [System.Text.Encoding]::Default)

Send-MailMessage -to "<rcpts>" -from "<sender>" -Subject "DBA Checks (<servername>)[<serverip>] " -smtpserver <mailserverip> -Body $MessageContent -BodyAsHtml -Encoding ([System.Text.Encoding]::UTF8)
