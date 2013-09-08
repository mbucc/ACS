# /admin/webmail/job-restart.tcl

ad_page_contract {
    Restart a broken job.

    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-04-03
    @cvs-id job-restart.tcl,v 1.3.2.3 2000/07/21 03:58:32 ron Exp
} {
    job:integer
}

set db [ns_db gethandle]

ns_db dml $db "begin dbms_job.broken($job, FALSE, sysdate); end;"

ad_returnredirect "problems.tcl"

