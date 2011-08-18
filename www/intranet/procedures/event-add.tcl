# $Id: event-add.tcl,v 3.2.2.1 2000/03/17 08:02:23 mbryzek Exp $
# File: /www/intranet/procedures/event-add.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: Form to certify a user in a procedure
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
    ad_return_error "Error" "You're not allowed to supervise users on this procedure"
    return
}

set event_id [database_to_tcl_string $db "select im_proc_event_id_seq.nextval from dual"]

set page_body "

[ad_header "Record a procedure"]

<H2>Record procedure</H2>

[ad_context_bar [list "/" Home] [list "../index.tcl" "Intranet"] [list "index.tcl" "Procedures"] "Record procedure"]

<HR>

Use this form to record the times an uncertified user did this procedure.
If you're confident enough in their ability, you can
<A HREF=user-add.tcl?procedure_id=$procedure_id>certify them</A>
instead.

<UL>
<LI>Procedure: $name
<BLOCKQUOTE><EM>$note</EM></BLOCKQUOTE>
</UL>

<BLOCKQUOTE>

<FORM METHOD=POST ACTION=event-add-2.tcl>
[export_form_vars event_id procedure_id]

<P>User supervised:
<SELECT NAME=user_id>
<option value=\"\"> -- Please select --
[ad_db_optionlist $db "select 
first_names || ' ' || last_name as name, u.user_id 
from users_active u
where ad_group_member_p ( u.user_id, [im_employee_group_id] ) = 't'
and not exists (select 1 
            from im_procedure_users ipu
            where ipu.user_id = u.user_id
            and procedure_id = $procedure_id)"]
</SELECT>

<P>Date supervised: [ad_dateentrywidget event_date]

<P>Notes:<BR>
<TEXTAREA NAME=note COLS=50 ROWS=8 WRAP=SOFT></TEXTAREA>

</UL>

<P><CENTER>
<INPUT TYPE=Submit VALUE=\" Record procedure \">
</CENTER>
</P>

</FORM>
</BLOCKQUOTE>

[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $page_body

