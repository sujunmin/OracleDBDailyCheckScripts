set markup html on preformat off entmap on 

spool <outputpath>


PROMPT ================================================================
PROMPT DATABASE HEALTH CHECK REPORT
PROMPT ================================================================

PROMPT
PROMPT
PROMPT DATABASE STATUS
PROMPT =================

select HOST_NAME,INSTANCE_NAME,STATUS,DATABASE_STATUS,ACTIVE_STATE,
       floor(sysdate - startup_time) || ' days(s), ' || 
       floor((sysdate - startup_time - floor(sysdate-startup_time)) * 24) || ' hour(s), ' || 
       floor(((sysdate - startup_time - floor(sysdate-startup_time)) * 24 - floor((sysdate - startup_time - floor(sysdate-startup_time)) * 24)) * 60) || ' min(s)' as UPTIME
from v$instance;


PROMPT
PROMPT
PROMPT DATABASE NAME AND MODE (CDB$ROOT)
PROMPT =================================

select name, open_mode, log_mode from v$database;


PROMPT
PROMPT
PROMPT DATABASE NAME AND MODE (PDB)
PROMPT ============================

select name, open_mode from v$pdbs;



PROMPT
PROMPT
PROMPT COUNT OF TABLESPACES
PROMPT ========================
select NVL((select name from v$pdbs where con_id = vt.con_id) ,'CDB$ROOT') AS "NAME", count(*) AS "No. of datafiles" from v$tablespace vt group by vt.con_id order by vt.con_id; 


PROMPT
PROMPT
PROMPT COUNT OF DATAFILES
PROMPT ========================

select NVL((select name from v$pdbs where con_id = vt.con_id) ,'CDB$ROOT') AS "NAME", count(*) AS "No. of datafiles" from v$datafile vt group by vt.con_id order by vt.con_id; 


PROMPT
PROMPT
PROMPT COUNT OF INVALID OBJECTS
PROMPT ==========================

select count(*) from all_objects where status='INVALID';


PROMPT
PROMPT
PROMPT COUNT OF ARCHIVED GENERATED LAST DAY
PROMPT =====================================
Select count(*) "No. of Archive Logs generated" from v$log_history  where to_char(first_time,'dd-mon-rrrr') in (to_char(sysdate-1,'dd-mon-rrrr'));



PROMPT
PROMPT
PROMPT DB PHYSICAL SIZE
PROMPT =====================================
select sum(vfu.file_size*vd.block_size/1024/1024/1024) "DB Physical Size(GB)" from v$filespace_usage vfu, v$datafile vd where vfu.tablespace_id = vd.ts# and vfu.con_id = vd.con_id;


PROMPT
PROMPT
PROMPT DB ACUTAL SIZE
PROMPT =====================================
select sum(vfu.allocated_space*vd.block_size/1024/1024/1024) "DB Actual Size(GB)" from v$filespace_usage vfu, v$datafile vd where vfu.tablespace_id = vd.ts# and vfu.con_id = vd.con_id;


PROMPT
PROMPT
PROMPT DICTIONARY HIT RATIO. THIS VALUE SHOULD BE GREATER 85%
PROMPT ==========================================================
select   (  1 - ( sum (decode (name, 'physical reads', value, 0)) / (  sum (decode (name, 'db block gets',value, 0)) + sum (decode (name, 'consistent gets', value, 0))))) * 100 "Buffer Hit Ratio" from v$sysstat;

PROMPT
PROMPT
PROMPT LIBRARY CACHE HIT RATIO. THIS VALUE SHOULD BE GREATER 90%
PROMPT ===========================================================
select (sum(pins)/(sum(pins)+sum(reloads))) * 100 "Library Cache Hit Ratio" from v$librarycache;



PROMPT
PROMPT
PROMPT PGA STATISTICS
PROMPT ===========================================================
COL SESSION FORMAT A45
SELECT   to_char(ssn.sid, '9999') || ' - ' || nvl(ssn.username, nvl(bgp.name, 'background')) || ' ' || nvl(lower(ssn.machine), ins.host_name) "SESSION",  to_char(prc.spid, '999999999') "PID/THREAD", to_char((se1.value/1024)/1024, '999G999G990D00') || ' MB' "      CURRENT SIZE",  to_char((se2.value/1024)/1024, '999G999G990D00') || ' MB' "      MAXIMUM SIZE"   FROM     v$sesstat se1,  v$sesstat se2,  v$session ssn,  v$bgprocess bgp,  v$process prc,  v$instance ins,  v$statname stat1, v$statname stat2  WHERE  prc.spid is not null and se1.statistic# = stat1.statistic# and stat1.name = 'session pga memory'  AND      se2.statistic#  = stat2.statistic# and stat2.name = 'session pga memory max' AND      se1.sid        = ssn.sid  AND      se2.sid        = ssn.sid  AND      ssn.paddr      = bgp.paddr (+) AND      ssn.paddr      = prc.addr  (+);


PROMPT
PROMPT
PROMPT UGA STATISTICS
PROMPT ===========================================================
SELECT   to_char(ssn.sid, '9999') || ' - ' || nvl(ssn.username, nvl(bgp.name, 'background')) || ' ' || nvl(lower(ssn.machine), ins.host_name) "SESSION",  to_char(prc.spid, '999999999') "PID/THREAD",  to_char((se1.value/1024)/1024, '999G999G990D00') || ' MB' "      CURRENT SIZE",  to_char((se2.value/1024)/1024, '999G999G990D00') || ' MB' "      MAXIMUM SIZE"  FROM     v$sesstat se1, v$sesstat se2, v$session ssn, v$bgprocess bgp, v$process prc,  v$instance ins,  v$statname stat1, v$statname stat2  WHERE  prc.spid is not null and se1.statistic# = stat1.statistic# and stat1.name = 'session uga memory'  AND  se2.statistic# = stat2.statistic# and stat2.name = 'session uga memory max'  AND se1.sid   = ssn.sid  AND se2.sid = ssn.sid  AND  ssn.paddr = bgp.paddr (+)  AND  ssn.paddr = prc.addr  (+);



PROMPT
PROMPT
PROMPT DATABASE STATISTICS
PROMPT ===========================================================
select NVL((select name from v$pdbs where con_id = vt.con_id) ,'CDB$ROOT') AS "PDB NAME", 
       vt.name as tablespace_name,  
       vd.name as file_name, 
       to_char(vfu.file_size*vd.block_size/1024/1024, '9999999.99') as "TOTAL(MB)", 
       to_char(vfu.allocated_space*vd.block_size/1024/1024,'9999999.99') as "USED(MB)", 
       to_char((vfu.allocated_space/vfu.file_size)*100,'999.999') as "USED(%)", 
       (select to_char(completion_time,'yyyy/mm/dd hh24:mi:ss') from (select completion_time from v$backup_datafile vbd where incremental_level = 0 and vbd.file# = vd.file# order by completion_time desc) where rownum <= 1) as "Last Full Backup", 
       (select to_char(completion_time,'yyyy/mm/dd hh24:mi:ss') from (select completion_time from v$backup_datafile vbd where incremental_level = 1 and vbd.file# = vd.file# order by completion_time desc) where rownum <= 1) as "Last Diff Backup" 
from v$datafile vd, v$tablespace vt , v$filespace_usage vfu 
where vd.ts# = vt.ts# and vd.con_id = vt.con_id  and vfu.tablespace_id = vt.ts# and vfu.con_id = vt.con_id order by "PDB NAME", tablespace_name,file_name;

PROMPT
PROMPT
PROMPT IO ACTIVITIES
PROMPT ===========================================================
select  vt.name as tablespace_name, regexp_replace(vd.name,'^.*.\/.*.\/', '') as file_name,sum(vf.phyrds) as reads, sum(vf.phywrts) as writes, sum(vf.phyrds)+sum(vf.phywrts) as total from v$datafile vd, v$filestat vf, v$tablespace vt where vd.file#=vf.file# and vd.con_id = vf.con_id and vd.ts# = vt.ts# and vt.con_id = vd.con_id and rownum <=10 group by vt.name, vd.name order by  total desc ;



PROMPT
PROMPT
PROMPT DATAFILE PHYSICAL READS AND WRITES
PROMPT ===========================================================
COL datafile FORMAT A45
select name datafile, phyrds reads, phywrts writes, phyrds+phywrts total from v$datafile a, v$filestat b where a.file# = b.file# order by total desc;

PROMPT
PROMPT
PROMPT JOB STATS IN THE LAST 3 DAYS
PROMPT ===========================================================
col JOB_NAME for a30
col "Last Start Time" for a20
col "Next Run Time" for a20
col "Last Result" for a20
select a.JOB_NAME, 
       count(DECODE(a.STATUS, 'SUCCEEDED', 1)) as "Succeeded", 
       count(DECODE(a.STATUS, 'FAILED', 1)) as "Failed", 
       count(DECODE(a.STATUS, 'STOPPED', 1)) as "Cancelled",
      (select to_char(LAST_START_DATE,'yyyy/mm/dd hh24:mi:ss') from all_scheduler_jobs where JOB_NAME=a.JOB_NAME) as "Last Start Time",
      (select to_char(NEXT_RUN_DATE,'yyyy/mm/dd hh24:mi:ss') from all_scheduler_jobs where JOB_NAME=a.JOB_NAME) as "Next Run Time",
      (select * from (select OUTPUT from all_scheduler_job_run_details where JOB_NAME=a.JOB_NAME order by ACTUAL_START_DATE desc) where rownum <=1) as "Last Result" 
from all_scheduler_job_run_details a
where a.ACTUAL_START_DATE >= (sysdate -3)
GROUP BY a.JOB_NAME
ORDER BY a.JOB_NAME;


PROMPT
PROMPT
PROMPT FAIL JOB IN THE LAST 3 DAYS
PROMPT ===========================================================
col "DATE" for a20
col JOB_NAME for a30
col STATUS for a10
col "MESSAGE" for a20
col RUN_DURATION for a20
select to_char(ACTUAL_START_DATE,'yyyy/mm/dd hh24:mi:ss') AS "DATE", JOB_NAME, STATUS, ERROR#, ADDITIONAL_INFO AS "MESSAGE", RUN_DURATION from SYS.all_scheduler_job_run_details where STATUS = 'FAILED' and ACTUAL_START_DATE >= (sysdate -3);


PROMPT
PROMPT
PROMPT BLOCKING QUERY
PROMPT ===========================================================
select s1.username || '@' || s1.machine|| ' ( SID=' || s1.sid || ' )  is blocking '|| s2.username || '@' || s2.machine || ' ( SID=' || s2.sid || ' ) ' AS blocking_status from v$lock l1, v$session s1, v$lock l2, v$session s2 where s1.sid=l1.sid and s2.sid=l2.sid and l1.BLOCK=1 and l2.request > 0 and l1.id1 = l2.id1 and l2.id2 = l2.id2;

PROMPT
PROMPT
PROMPT BLOCKER AND WAITER
PROMPT ===========================================================
Select sid , decode(block,0,'NO','YES') Blocker , decode (request ,0,'NO','YES')WAITER from v$lock where request>0 or block>0 order by block desc;


PROMPT
PROMPT
PROMPT NO of USER CONNECTED
PROMPT ===========================================================
select count(distinct username) "No. of users Connected" from v$session where username is not null;



PROMPT
PROMPT
PROMPT NO of SESSIONS CONNECTED
PROMPT ===========================================================
Select count(*) AS "No of Sessions connected" from v$session where username is not null;


PROMPT
PROMPT
PROMPT DISTINCT USERNAME CONNECTED
PROMPT ===========================================================
Select distinct(username) AS "USERNAME" from v$session;



PROMPT
PROMPT
PROMPT INVALID OBJECT LIST
PROMPT ===========================================================
COL object_name FORMAT A40
select owner , object_name , object_type , status from all_objects where status='INVALID' order by owner , object_type , object_name;





Spool off

exit
