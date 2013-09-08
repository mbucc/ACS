# /www/intranet/procedures/user-add.tcl

ad_page_contract {
    Purpose: Certify a new user

    @param procedure_id the value of the procedure for which we're certifying a user 

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id user-add.tcl,v 3.6.6.10 2000/09/22 01:38:43 kevin Exp
} {
    procedure_id:integer
}

set caller_id [ad_maybe_redirect_for_registration]

if {![db_0or1row procedure_scan "select procedure_id, name, note from im_procedures \
	where procedure_id = :procedure_id"]} {
    ad_return_error "Error" "That procedure doesn't exist"
    return
} 


if {[db_string user_certify "select count(*) from im_procedure_users \
	where user_id = :caller_id and procedure_id = :procedure_id"] == 0} {
    ad_return_error "Error" "You're not allowed to certify new users"
    return
}

set context_bar [ad_context_bar_ws [list "index" "Procedures"] "Certify a user"]
set page_body "
[im_header "Certify a user"]

<FORM METHOD=POST ACTION=user-edit-2>
[export_form_vars procedure_id]

<UL>
<LI>Procedure: <B>$name</B>

<P><BLOCKQUOTE><EM>$note</EM></BLOCKQUOTE>

<P><LI>Certify user: 
<SELECT NAME=user_id>
<option value=\"\"> -- Please select --


[db_html_select_value_options -select_option $caller_id certifying_user "select 
u.user_id, first_names || ' ' || last_name as name
from users_active u
where ad_group_member_p ( u.user_id, [im_employee_group_id] ) = 't'
and not exists (select 1 from im_procedure_users ipu
            where ipu.user_id = u.user_id
            and procedure_id = :procedure_id)
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



doc_return  200 text/html $page_body



