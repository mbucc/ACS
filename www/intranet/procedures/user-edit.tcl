# $Id: user-edit.tcl,v 3.1.4.1 2000/03/17 08:02:28 mbryzek Exp $
# File: /www/intranet/procedures/user-edit.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: form to change restrictions on a procedure
#

set_form_variables
# procedure_id user_id

set caller_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "
select * from im_procedures where procedure_id = $procedure_id"]

if [empty_string_p $selection] {
    ad_return_error "Error" "That procedure doesn't exist"
    return
}
set_variables_after_query

if {[database_to_tcl_string $db "
select count(*) 
from im_procedure_users 
where user_id = $user_id 
and procedure_id = $procedure_id
and user_id != $caller_id"] == 0} {
    ad_return_error "Error" "You're not allowed to change this information"
    return
}

set selection [ns_db 0or1row $db "
select
    u.first_names || ' ' || u.last_name as user_name,
    ip.name as procedure_name,
    ip.note as procedure_note,
    ipu.note as restrictions
from users u, im_procedures ip, im_procedure_users ipu
where u.user_id = $user_id
and ip.procedure_id = $procedure_id
and ip.procedure_id = ipu.procedure_id
and u.user_id = ipu.user_id"]

set_variables_after_query

set page_body "

[ad_header "Change restrictions"]

<H2>Change restrictions</H2>

[ad_context_bar [list "/" Home] [list "index.tcl" "Intranet"] [list "procedures.tcl" "Procedures"] "Change restrictions"]

<HR>

<FORM METHOD=POST ACTION=procedure-user-edit-2.tcl>
[export_form_vars user_id procedure_id]

<UL>
<LI>Procedure: <B>$procedure_name</B>

<P><BLOCKQUOTE><EM>$procedure_note</EM></BLOCKQUOTE>

<LI>User: $user_name

<P>Restrictions:<BR>
<TEXTAREA NAME=note COLS=50 ROWS=8 WRAP=SOFT>[ns_quotehtml $restrictions]</TEXTAREA>

</UL>

<P><CENTER>
<INPUT TYPE=Submit VALUE=\" Update \">
</CENTER>
</P>

</FORM>

[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $page_body

