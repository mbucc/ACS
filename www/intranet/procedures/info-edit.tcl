# $Id: info-edit.tcl,v 3.1.4.1 2000/03/17 08:02:24 mbryzek Exp $
# File: /www/intranet/procedures/info-edit.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: Form to edit procedure information
#

set_form_variables
# procedure_id

set caller_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

if {[database_to_tcl_string $db "select count(*) from im_procedure_users where user_id = $caller_id and procedure_id = $procedure_id"] == 0} {
    ad_return_error "Error" "You're not allowed to edit this information"
    return
}

set selection [ns_db 0or1row $db "
select * from im_procedures where procedure_id = $procedure_id"]

if [empty_string_p $selection] {
    ad_return_error "Error" "That procedure doesn't exist"
    return
}
set_variables_after_query

set page_body "

[ad_header $name]

<H2>$name</H2>

[ad_context_bar [list "/" Home] [list "../index.tcl" "Intranet"] [list "index.tcl" "Procedures"] "Edit Procedure info"]

<HR>

<BLOCKQUOTE>
<FORM METHOD=POST ACTION=info-edit-2.tcl>
[export_form_vars procedure_id]

<P>The procedure:<BR>
<INPUT NAME=name SIZE=50 [export_form_value name]>

<P>Notes on the procedure<BR>
<TEXTAREA NAME=note COLS=50 ROWS=12 WRAP=SOFT>[ns_quotehtml $note]</TEXTAREA>

<P><CENTER>
<INPUT TYPE=Submit VALUE=\" Update \">
</CENTER></P>

</BLOCKQUOTE>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $page_body