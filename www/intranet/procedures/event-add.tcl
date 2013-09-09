# /www/intranet/procedures/event-add.tcl

ad_page_contract {
    Purpose: Form to certify a user in a procedure
    
    @param procedure_id procedure for which we're registering this event

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id event-add.tcl,v 3.6.6.10 2001/01/12 17:00:09 khy Exp
} {
    procedure_id:naturalnum,notnull
}


set caller_id [ad_maybe_redirect_for_registration]

if { ![db_0or1row procedure_id_exists {
    select p.name, p.note, p.creation_date, p.creation_user, p.last_modified, p.last_modifying_user
      from im_procedures p
     where procedure_id = :procedure_id}] } {
    ad_return_error "Error" "Procedure $procedure_id doesn't exist"
    return
}


if {[db_string user_permitted "select count(*) from im_procedure_users where user_id = :caller_id and procedure_id = :procedure_id"] == 0} {
    ad_return_error "Error" "You're not allowed to supervise users on this procedure"
    return
}

db_1row seqval_read "select im_proc_event_id_seq.nextval as event_id from dual"

set context_bar [ad_context_bar_ws [list "index" "Procedures"] [list info?[export_url_vars procedure_id] "One procedure"] "Record event"]

set page_body "
[im_header "Record a procedure"]

Use this form to record the times an uncertified user did this procedure.
If you're confident enough in their ability, you can
<A HREF=user-add?procedure_id=$procedure_id>certify them</A>
instead.

<UL>
<LI>Procedure: $name
<BLOCKQUOTE><EM>$note</EM></BLOCKQUOTE>
</UL>

<BLOCKQUOTE>

<FORM METHOD=post ACTION=event-add-2>
[export_form_vars -sign event_id]
[export_form_vars procedure_id]

<P>User supervised:
<SELECT NAME=user_id>
<option value=\"\"> -- Please select --

[db_html_select_value_options certifying_user "select 
u.user_id, first_names || ' ' || last_name as name
from im_employees_active u
where not exists (select 1 
            from im_procedure_users ipu
            where ipu.user_id = u.user_id
and procedure_id = :procedure_id)"]
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

[im_footer]
"

doc_return  200 text/html $page_body


