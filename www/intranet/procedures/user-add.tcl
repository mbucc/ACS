# $Id: user-add.tcl,v 3.2.2.1 2000/03/17 08:02:26 mbryzek Exp $
# File: /www/intranet/procedures/user-add.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: Certify a new user
#

set_form_variables
# procedure_id

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

if {[database_to_tcl_string $db "select count(*) from im_procedure_users where user_id = $caller_id and procedure_id = $procedure_id"] == 0} {
    ad_return_error "Error" "You're not allowed to certify new users"
    return
}

set page_body "

[ad_header "Certify a user"]

<H2>Certify a user</H2>

[ad_context_bar [list "/" Home] [list "../index.tcl" "Intranet"] [list "index.tcl" "Procedures"] "Certify a user"]

<HR>

<FORM METHOD=POST ACTION=user-edit-2.tcl>
[export_form_vars procedure_id]

<UL>
<LI>Procedure: <B>$name</B>

<P><BLOCKQUOTE><EM>$note</EM></BLOCKQUOTE>

<P><LI>Certify user: 
<SELECT NAME=user_id>
<option value=\"\"> -- Please select --
[ad_db_optionlist $db "select 
first_names || ' ' || last_name as name, u.user_id 
from users_active u
where ad_group_member_p ( u.user_id, [im_employee_group_id] ) = 't'
and not exists (select 1 from im_procedure_users ipu
            where ipu.user_id = u.user_id
            and procedure_id = $procedure_id)
order by lower(name)"]
</SELECT>

<P>Notes/restrictions (<EM>e.g., only certified on HPUX</EM>):<BR>
<TEXTAREA NAME=note COLS=50 ROWS=8 WRAP=SOFT></TEXTAREA>

</UL>

<P><CENTER>
<INPUT TYPE=Submit VALUE=\" Certify user \">
</CENTER>
</P>

</FORM>

[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $page_body