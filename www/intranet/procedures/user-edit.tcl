# /www/intranet/procedures/user-edit.tcl

ad_page_contract {
    Purpose: form to change restrictions on a procedure

    @param procedure_id the procedure we're editing
    @param user_id user to edit
    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id user-edit.tcl,v 3.7.2.9 2000/09/22 01:38:43 kevin Exp
} {
    procedure_id:integer
    user_id:integer
}

set caller_id [ad_maybe_redirect_for_registration]


if {![db_0or1row procedure_scan "select creation_user from im_procedures \
	where procedure_id = :procedure_id"]} {
    ad_return_error "Error" "That procedure doesn't exist"
    return
}


if {$caller_id != $user_id && [db_string certify_user "
select count(*) 
from im_procedure_users 
where user_id = :user_id 
and procedure_id = :procedure_id"] } {
    ad_return_error "Error" "You're not allowed to change this information"
    return
}


db_1row procedure_details "
select
    u.first_names || ' ' || u.last_name as user_name,
    ip.name as procedure_name,
    ip.note as procedure_note,
    ipu.note as restrictions
from users u, im_procedures ip, im_procedure_users ipu
where u.user_id = $user_id
and ip.procedure_id = :procedure_id
and ip.procedure_id = ipu.procedure_id
and u.user_id = ipu.user_id"


set page_title "Change restrictions"
set context_bar [ad_context_bar_ws [list "./" "Procedures"] "Change restrictions"]

set page_content "

<FORM METHOD=POST ACTION=user-edit-2>
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
"



doc_return  200 text/html [im_return_template]


