# $Id: user-info.tcl,v 3.1.4.1 2000/03/17 08:02:28 mbryzek Exp $
# File: /www/intranet/procedures/user-info.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: Displays info about a certified user
#

set_form_variables
# procedure_id user_id

set caller_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "
select 
    ip.name as procedure_name,
    ip.note as procedure_note,
    ipu.note as restrictions,
    u1.first_names || ' ' || u1.last_name as user_name,  
    u2.first_names || ' ' || u2.last_name as certifying_user_name,
    ipu.certifying_date
from users u1, users u2, im_procedures ip, im_procedure_users ipu
where ip.procedure_id = $procedure_id
and ip.procedure_id = ipu.procedure_id
and u1.user_id = $user_id
and u2.user_id = ipu.certifying_user
and ipu.user_id = u1.user_id"]

if [empty_string_p $selection] {
    ad_return_error "Error" "That user isn't certified to do that procedure"
    return
}
set_variables_after_query

if [empty_string_p $restrictions] {
    set restrictions "None"
}

set page_body "

[ad_header $user_name]

<H2>$user_name</H2>

[ad_context_bar [list "/" Home] [list "../index.tcl" "Intranet"] [list "index.tcl" "Procedures"] "User info"]

<HR>

<UL>
<LI>Name: <A HREF=../users/view.tcl?user_id=$user_id>$user_name</A>
<LI>Procedure: $procedure_name

<BLOCKQUOTE>
<EM>$procedure_note</EM>
</BLOCKQUOTE>

<P><LI>Certified [util_AnsiDatetoPrettyDate $certifying_date] by $certifying_user_name

<P><EM>Restrictions:</EM> $restrictions 

"

if {($user_id != $caller_id) &&
    ([database_to_tcl_string $db "select count(*) from im_procedure_users
                                  where procedure_id = $procedure_id
                                  and user_id = $user_id"] > 0)} {
    append page_body "(<A HREF=procedure-user-edit.tcl?[export_url_vars user_id procedure_id]>edit</A>)"
}

set selection [ns_db select $db "
select
    u.user_id as certified_user,
    u.first_names || ' ' || u.last_name as certified_user_name,
    ipu.certifying_date
from users u, im_procedure_users ipu
where ipu.procedure_id = $procedure_id
and ipu.user_id != $user_id
and ipu.certifying_user = $user_id
and ipu.user_id = u.user_id
order by certifying_date"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append users_certified "<LI><A HREF=procedure-user-info.tcl?user_id=$certified_user&procedure_id=$procedure_id>$certified_user_name</A> on [util_AnsiDatetoPrettyDate $certifying_date]\n"
}

if [info exists users_certified] {
    append page_body "<P><EM>Users certified by $user_name</EM>
<UL>
$users_certified
</UL>
"
}

set selection [ns_db select $db "
select
    u.user_id as supervised_user_id,
    u.first_names || ' ' || u.last_name as supervised_user_name,
    ipe.event_date
from users u, im_procedure_events ipe
where ipe.procedure_id = $procedure_id
and ipe.user_id != $user_id
and ipe.supervising_user = $user_id
and ipe.user_id = u.user_id
and not exists (select 1 from im_procedure_users ipu 
                where ipu.user_id = u.user_id
                and ipu.procedure_id = $procedure_id)
order by event_date"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append users_supervised "<LI><A HREF=user-info.tcl?user_id=$supervised_user_id>$supervised_user_name</A> on [util_AnsiDatetoPrettyDate $event_date]\n"
}

if [info exists users_supervised] {
    append page_body "<P><EM>Uncertified users supervised by $user_name</EM>
<UL>
$users_supervised
</UL>
"
}

append page_body "
</UL>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html [ad_partner_return_template]