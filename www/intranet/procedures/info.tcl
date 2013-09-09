# /www/intranet/procedures/info.tcl

ad_page_contract {
    Purpose: lists information about 1 procedure
    
    @param procedure_id:  the procedure to display info on

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id info.tcl,v 3.6.6.12 2000/09/22 01:38:43 kevin Exp
} {
    procedure_id:integer
}


set caller_id [ad_maybe_redirect_for_registration]


set procedure_id_summary_sql "select procedure_id, note, name from im_procedures where procedure_id = :procedure_id" 


if { [db_0or1row procedure_id_summary $procedure_id_summary_sql] == 0} {
    ad_return_error "Error" "That procedure doesn't exist"
    return
}   

set page_title "$name"
set context_bar [ad_context_bar_ws [list "index" "Procedures"] "One procedure"]

set page_body "
<blockquote>
[util_decode $note "" "<em>No description</em>" $note]
"

set edit_proc_sql "select count(*) from im_procedure_users where procedure_id = :procedure_id and user_id = :caller_id"

if {[db_string edit_proc $edit_proc_sql] > 0} {
    append page_body "<p>(<a href=info-edit?[export_url_vars procedure_id]>edit</a>)\n"
}





append page_body "
</BLOCKQUOTE>

<H4>People certified to do this procedure</H4>

"

set restrictions_list_sql "
select 
    u.user_id, 
    u.first_names || ' ' || u.last_name as user_name,
    pu.certifying_date,
    u2.first_names || ' ' || u2.last_name as certifying_user_name,
    pu.note as restrictions
from users_active u, users_active u2, im_procedure_users pu, im_procedures p
where p.procedure_id = :procedure_id
and p.procedure_id = pu.procedure_id
and u.user_id = pu.user_id
and u2.user_id = pu.certifying_user
order by certifying_date"

set certified_users ""
set list_of_users {}

db_foreach restrictions_list $restrictions_list_sql {
    if ![empty_string_p $restrictions] {
        set restrictions "Restrictions: $restrictions"
    }
    append certified_users "<LI><A HREF=user-info?[export_url_vars user_id procedure_id]>$user_name</A>,
<FONT SIZE=-1> certified [util_AnsiDatetoPrettyDate $certifying_date] by $certifying_user_name<BR>
&nbsp;&nbsp;$restrictions</FONT>\n"
    lappend list_of_users $user_id
} if_no_rows {
    set certified_users "<EM>none</EM>"
}

if {[lsearch -exact $list_of_users $caller_id] != -1} {
    set caller_certified_p 1
    append certified_users "<P><A HREF=user-add?procedure_id=$procedure_id>Certify a user</A>"
} else {
    set caller_certified_p 0
}

append page_body "

<UL>
$certified_users
</UL>

<H4>Uncertified people who have done this procedure</H4>

"


set uncertified_users_sql "
select
    u.user_id, 
    u.first_names || ' ' || u.last_name as user_name,
    pe.event_date,
    u2.first_names || ' ' || u2.last_name as supervising_user_name,
    pe.note as event_note
from users_active u, users_active u2, im_procedure_events pe, im_procedures p
where p.procedure_id = :procedure_id
and p.procedure_id = pe.procedure_id
and u.user_id = pe.user_id
and u2.user_id = pe.supervising_user
and not exists (select 1 from im_procedure_users ipu 
                where ipu.user_id = u.user_id
                and ipu.procedure_id = :procedure_id) 
order by event_date"


set events ""


db_foreach uncertified_users $uncertified_users_sql {
    append events "<LI><A HREF=../users/view?[export_url_vars user_id]>$user_name</A>, <FONT SIZE=-1>supervised by $supervising_user_name on [util_AnsiDatetoPrettyDate $event_date]"
    if ![empty_string_p $note] {
        append events "<BR>&nbsp; &nbsp; $event_note\n"
    }
    append events "</FONT>\n"
} if_no_rows {
    set events "<EM>None</EM>"
}



if {$caller_certified_p} {
    append events "<P><A HREF=event-add?procedure_id=$procedure_id>Add a record</A>"
}

append page_body "

<UL>
$events
</UL>
"



doc_return  200 text/html [im_return_template]


