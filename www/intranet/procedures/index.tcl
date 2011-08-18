# $Id: index.tcl,v 3.1.4.1 2000/03/17 08:02:24 mbryzek Exp $
# File: /www/intranet/procedures/index.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: lists all procedures
#

set page_body "

<blockquote>

Use this section to record company procedures and 
the people certified to do them. 
<P>How to use:

<UL>
<LI>Anyone can add a procedure, and they're allowed to pick
the first person certified for that procedure.
<LI>Anyone certified in procedure <EM>X</EM> can certify anyone else
to do that procedure. (That person can also add restrictions like
<EM>only certified on HPUX</EM>)
<LI>Certified users should record times they supervised 
a non-certified user doing a procedure, so we can use rules
like <EM>A user can be certified after completing the procedure
5 times under the supervision of a certified user</EM>.
</UL>

<H4>The procedures</H4>

<dl>
"

set db [ns_db gethandle]

set selection [ns_db select $db "
select 
    p.procedure_id,
    p.name as proc_name,
    u.user_id,
    u.first_names || ' ' || u.last_name as user_name
from im_procedures p, im_procedure_users pu, users_active u
where p.procedure_id = pu.procedure_id(+)
and pu.user_id = u.user_id(+)
order by proc_name, user_name"]

set list_of_procedures ""

set last_procedure_id ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if {$procedure_id != $last_procedure_id} {
        append list_of_procedures "<p><dt><a href=info.tcl?[export_url_vars procedure_id]>$proc_name</A>\n"
    }
    append list_of_procedures "  <dd>$user_name\n"
    set last_procedure_id $procedure_id
}

if [empty_string_p $list_of_procedures] {
    set list_of_procedures "<EM>No procedures exist</EM>"
}

append page_body "

$list_of_procedures

</DL>

<P><BR><A HREF=add.tcl>Add a procedure</A>
</BLOCKQUOTE>
"

ns_db releasehandle $db

set page_title "Procedures"
set context_bar [ad_context_bar [list "/" Home] [list "../index.tcl" "Intranet"] "Procedures"]

ns_return 200 text/html [ad_partner_return_template]