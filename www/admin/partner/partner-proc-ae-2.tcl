# $Id: partner-proc-ae-2.tcl,v 3.0.4.1 2000/04/28 15:09:13 carsten Exp $
set_the_usual_form_variables
# url_id, proc_name, proc_id, proc_type, call_number

# Check arguments
set err ""
set req_vars [list url_id proc_id proc_name proc_type call_number]
foreach var $req_vars {
    if {![exists_and_not_null $var] } {
	append err "  <LI> Must specify $var\n"
    }
}

set db [ns_db gethandle]

# Check for uniqueness
set exists_p [database_to_tcl_string $db "select decode(count(*),0,0,1) 
                                          from ad_partner_procs 
                                          where url_id='$QQurl_id' 
                                          and proc_name='$QQproc_name' 
                                          and proc_id<>$proc_id
                                          and proc_type='$QQproc_type'"]

if { $exists_p } {
    append err "  <li> Specified proc \"$proc_name\" has already been registered for this partner and url\n"
}

if { ![empty_string_p $err] } {
    ad_partner_return_error "Missing Arguments" "<UL> $err</UL>"
    return
}

ns_db dml $db "begin transaction"

ns_db dml $db "update ad_partner_procs set 
               proc_name='$QQproc_name'
               where proc_id = $proc_id"

if {[ns_ora resultrows $db] == 0} {
    ns_db dml $db "insert into ad_partner_procs
(url_id, proc_id, proc_name, proc_type, call_number)
values 
($url_id, $proc_id, '$QQproc_name', '$QQproc_type', $call_number)"
}

ns_db dml $db "end transaction"

ad_returnredirect "partner-url.tcl?[export_url_vars url_id]"

