# $Id: info.tcl,v 3.1.4.1 2000/03/17 08:02:25 mbryzek Exp $
# File: /www/intranet/procedures/info.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: lists information about 1 procedure
#

set_form_variables
# procedure_id

set caller_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set selection [ns_db 0or1row $db \
	"select * from im_procedures where procedure_id = $procedure_id"]

if [empty_string_p $selection] {
    ad_return_error "Error" "That procedure doesn't exist"
    return
}
set_variables_after_query

set page_title $name
set context_bar [ad_context_bar [list "/" Home] [list "../index.tcl" "Intranet"] [list "index.tcl" "Procedures"] "One procedure"]

set page_body "
<blockquote>
[util_decode $note "" "<em>No description</em>" $note]
"

if {[database_to_tcl_string $db \
	"select count(*) from im_procedure_users where procedure_id = $procedure_id and user_id = $caller_id"] > 0} {
    append page_body "<p>(<a href=info-edit.tcl?[export_url_vars procedure_id]>edit</a>)\n"
}

append page_body "
</BLOCKQUOTE>

<H4>People certified to do this procedure</H4>

"

set selection [ns_db select $db "
select 
    u.user_id, 
    u.first_names || ' ' || u.last_name as user_name,
    pu.certifying_date,
    u2.first_names || ' ' || u2.last_name as certifying_user_name,
    pu.note as restrictions
from users_active u, users_active u2, im_procedure_users pu, im_procedures p
where p.procedure_id = $procedure_id
and p.procedure_id = pu.procedure_id
and u.user_id = pu.user_id
and u2.user_id = pu.certifying_user
order by certifying_date"]

set certified_users ""
set list_of_users {}

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if ![empty_string_p $restrictions] {
        set restrictions "Restrictions: $restrictions"
    }
    append certified_users "<LI><A HREF=user-info.tcl?[export_url_vars user_id procedure_id]>$user_name</A>,
<FONT SIZE=-1> certified [util_AnsiDatetoPrettyDate $certifying_date] by $certifying_user_name<BR>
&nbsp;&nbsp;$restrictions</FONT>\n"
    lappend list_of_users $user_id
}

if [empty_string_p $certified_users] {
    set certified_users "<EM>none</EM>"
}

if {[lsearch -exact $list_of_users $caller_id] != -1} {
    set caller_certified_p 1
    append certified_users "<P><A HREF=user-add.tcl?procedure_id=$procedure_id>Certify a user</A>"
} else {
    set caller_certified_p 0
}

append page_body "

<UL>
$certified_users
</UL>

<H4>Uncertified people who have done this procedure</H4>

"

set selection [ns_db select $db "
select
    u.user_id, 
    u.first_names || ' ' || u.last_name as user_name,
    pe.event_date,
    u2.first_names || ' ' || u2.last_name as supervising_user_name,
    pe.note as event_note
from users_active u, users_active u2, im_procedure_events pe, im_procedures p
where p.procedure_id = $procedure_id
and p.procedure_id = pe.procedure_id
and u.user_id = pe.user_id
and u2.user_id = pe.supervising_user
and not exists (select 1 from im_procedure_users ipu 
                where ipu.user_id = u.user_id
                and ipu.procedure_id = $procedure_id) 
order by event_date"]

set events ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append events "<LI><A HREF=../users/view.tcl?[export_url_vars user_id]>$user_name</A>, <FONT SIZE=-1>supervised by $supervising_user_name on [util_AnsiDatetoPrettyDate $event_date]"
    if ![empty_string_p $note] {
        append events "<BR>&nbsp; &nbsp; $event_note\n"
    }
    append events "</FONT>\n"
}

if [empty_string_p $events] {
    set events "<EM>None</EM>"
}

if {$caller_certified_p} {
    append events "<P><A HREF=event-add.tcl?procedure_id=$procedure_id>Add a record</A>"
}

append page_body "

<UL>
$events
</UL>
"

ns_db releasehandle $db

ns_return 200 text/html [ad_partner_return_template]