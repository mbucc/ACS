# /www/intranet/procedures/user-info.tcl

ad_page_contract {
    Purpose: Displays info about a certified user

    @param procedure_id the procedure we're modifying
    @param user_id user we're investigating

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id user-info.tcl,v 3.6.6.8 2000/09/22 01:38:43 kevin Exp
} {
    procedure_id:integer
    user_id:integer
}

set caller_id [ad_maybe_redirect_for_registration]


set certify_user_sql "
select 
    ip.name as procedure_name,
    ip.note as procedure_note,
    ipu.note as restrictions,
    u1.first_names || ' ' || u1.last_name as user_name,  
    u2.first_names || ' ' || u2.last_name as certifying_user_name,
    ipu.certifying_date
from users u1, users u2, im_procedures ip, im_procedure_users ipu
where ip.procedure_id = :procedure_id
and ip.procedure_id = ipu.procedure_id
and u1.user_id = :user_id
and u2.user_id = ipu.certifying_user
and ipu.user_id = u1.user_id"


if {[db_0or1row certify_user $certify_user_sql] == 0 } {
    ad_return_error "Error" "That user isn't certified to do that procedure"
    return
}   

if [empty_string_p $restrictions] {
    set restrictions "None"
}

set page_title $user_name
set context_bar [ad_context_bar_ws [list "index" "Procedures"] "User info"]

set page_content "

<UL>
<LI>Name: <A HREF=../users/view?user_id=$user_id>$user_name</A>
<LI>Procedure: $procedure_name

<BLOCKQUOTE>
<EM>$procedure_note</EM>
</BLOCKQUOTE>

<P><LI>Certified [util_AnsiDatetoPrettyDate $certifying_date] by $certifying_user_name

<P><EM>Restrictions:</EM> $restrictions 

"

if {($user_id == $caller_id) ||
    ([db_string edit_user "select count(*) from im_procedure_users
                                  where procedure_id = :procedure_id
                                  and user_id = :caller_id"] > 0)} {
    append page_content "(<A HREF=user-edit?[export_url_vars user_id procedure_id]>edit</A>)"
}


set names_list_sql "
select
    u.user_id as certified_user,
    u.first_names || ' ' || u.last_name as certified_user_name,
    ipu.certifying_date
from users u, im_procedure_users ipu
where ipu.procedure_id = :procedure_id
and ipu.user_id != :user_id
and ipu.certifying_user = :user_id
and ipu.user_id = u.user_id
order by certifying_date"

db_foreach names_list $names_list_sql {
    append users_certified "<LI><A HREF=user-info?user_id=$certified_user&procedure_id=$procedure_id>$certified_user_name</A>on [util_AnsiDatetoPrettyDate $certifying_date]\n"
}


if [info exists users_certified] {
    append page_content "<P><EM>Users certified by $user_name</EM>
<UL>
$users_certified
</UL>
"
} 


set supervise_users_sql "
select
    u.user_id as supervised_user_id,
    u.first_names || ' ' || u.last_name as supervised_user_name,
    ipe.event_date
from users u, im_procedure_events ipe
where ipe.procedure_id = :procedure_id
and ipe.user_id != :user_id
and ipe.supervising_user = :user_id
and ipe.user_id = u.user_id
and not exists (select 1 from im_procedure_users ipu 
                where ipu.user_id = u.user_id
                and ipu.procedure_id = :procedure_id)
order by event_date"

db_foreach supervise_users $supervise_users_sql {
    append users_supervised "<LI><A HREF=../users/view?user_id=$supervised_user_id>$supervised_user_name</A> on [util_AnsiDatetoPrettyDate $event_date]\n"
}


if [info exists users_supervised] {
    append page_content "<P><EM>Uncertified users supervised by $user_name</EM>
<UL>
$users_supervised
</UL>
"
}

append page_content "</UL>\n"



doc_return  200 text/html [im_return_template]







