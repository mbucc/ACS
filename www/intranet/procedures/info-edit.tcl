# /www/intranet/procedures/info-edit.tcl

ad_page_contract {
    Purpose: Form to edit procedure information

    @param  procedure_id  the proc we're editing data for

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id info-edit.tcl,v 3.5.6.11 2000/09/22 01:38:43 kevin Exp
} {
    procedure_id:integer
}

set caller_id [ad_maybe_redirect_for_registration]



if {[db_string procedure_access_allowed \
"select count(*) from im_procedure_users 
where user_id = $caller_id 
and procedure_id = :procedure_id"] == 0} {
    ad_return_error "Error" "You're not allowed to edit this information"
    return
}


if { [db_0or1row procedure_id_exists \
"select procedure_id, name, note from im_procedures where procedure_id = :procedure_id"] == 0 } {
    ad_return_error "Error" "That procedure doesn't exist"
    return
}

set context_bar [ad_context_bar_ws [list "index" "Procedures"] "Edit Procedure info"]
set page_body "
[im_header $name]

<BLOCKQUOTE>
<FORM METHOD=POST ACTION=info-edit-2>
[export_form_vars procedure_id]

<P>The procedure:<BR>
<INPUT NAME=name SIZE=50 [export_form_value name]>

<P>Notes on the procedure<BR>
<TEXTAREA NAME=note COLS=50 ROWS=12 WRAP=SOFT>[ns_quotehtml $note]</TEXTAREA>

<P><CENTER>
<INPUT TYPE=Submit VALUE=\" Update \">
</CENTER></P>

</BLOCKQUOTE>
[im_footer]
"



doc_return  200 text/html $page_body






