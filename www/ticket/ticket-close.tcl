# /www/ticket/ticket-close.tcl
ad_page_contract {
    Misleadingly named, this page can actually change any code, not just 
    the status code. Furthermore, it isn't even used anymore.

    @param msg_id the ID for this ticket
    @param what which code to modify
    @param value the new value
    @param reopen unused variable
    @param return_url where to head next

    @author original author unknown
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @cvs-id ticket-close.tcl,v 3.1.6.4 2000/07/21 04:04:32 ron Exp
} {
    msg_id:integer,notnull
    what
    value
    {reopen 0}
    {return_url "/ticket/"}
}

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]

# given a what (code_type) we look up the value and set it on the 
# ticket

if {![db_0or1row find_id_for_code "
select code_id 
from   ticket_codes tc, 
       ticket_issues ti, 
       ticket_projects tp 
where  ti.msg_id = :msg_id 
and    tp.project_id  = ti.project_id 
and    tp.code_set = tc.code_set 
and    code = :value"]} {

    ad_return_complaint 1 "<LI> TR\#$msg_id does not have a code for $what:$value"
    return
}

db_dml code_update "
update ticket_issues_i 
set    :code = :code_id 
where  msg_id = :msg_id"

ad_returnredirect $return_url
