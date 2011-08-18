# $Id: running-jobs.tcl,v 3.0 2000/02/06 03:25:16 ron Exp $
set page_name "Currently Running Jobs"
ReturnHeaders
set db [cassandracle_gethandle]

ns_write "
[ad_admin_header $page_name]
<table>
<tr><th>ID</th><th>Submitted By</th><th>Security</th><th>Job</th><th>Last OK Date</th><th>Last OK Time</th><th>This Run Date</th><th>This Run Time</th><th>Errors</th></tr>
"



set job_running_info [database_to_tcl_list_list $db "Select R.job, J.Log_User, J.Priv_USER, J.What, R.Last_Date, SUBSTR(R.Last_Sec, 1, 5), R.This_Date, SUBSTR(R.This_Sec, 1, 5), R.Failures from DBA_JOBS_RUNNING R, DBA_JOBS J where R.JOB=J.JOB"]

if {[llength $job_running_info]==0} {
    ns_write "<tr><td>No Running Jobs found!</td></tr>"
} else {
    foreach row $job_running_info {
	ns_write "<tr><td>[lindex $row 0]</td><td>[lindex $row 1]</td><td>[lindex $row 2]</td><td>[lindex $row 3]</td><td>[lindex $row 4]</td><td>[lindex $row 5]</td><td>[lindex $row 6]</td><td>[lindex $row 7]</td><td>[lindex $row 8]</td>
</tr>\n"
    }
}
ns_write "</table>\n
<p>
Here is the SQL responsible for this information: <p>
<kbd>Select R.job, J.Log_User, J.Priv_USER, J.What, R.Last_Date, SUBSTR(R.Last_Sec, 1, 5), R.This_Date, SUBSTR(R.This_Sec, 1, 5), R.Failures<br>
from DBA_JOBS_RUNNING R, DBA_JOBS J<br>
where R.JOB=J.JOB</kbd>
[ad_admin_footer]
"
