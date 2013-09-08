# /www/intranet/procedures/add.tcl

ad_page_contract {
    Form to enter necessary info about a new procedure

    @param none no parameters passed in

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id add.tcl,v 3.7.6.10 2001/01/12 08:53:21 khy Exp
} {
    
}

set user_id [ad_maybe_redirect_for_registration]

set procedure_id [db_nextval "im_procedures_procedure_id_seq"]

set page_title "Add a procedure"
set context_bar [ad_context_bar_ws [list "index" "Procedures"] "Add procedure"]

set employee_group_id [im_employee_group_id]

set page_body "
<blockquote>

<form method=post action=add-2>
[export_form_vars -sign procedure_id]

[im_format_number 1] The procedure:
<br><dd><input type=text size=50 maxlength=200 name=name [export_form_value name]>

<p>[im_format_number 2] Notes on the procedure:
<br><dd><textarea name=note cols=50 rows=8 wrap=soft>[philg_quote_double_quotes [value_if_exists note]]</textarea>

<p>[im_format_number 3] The first person certified to do the procedure (and the
person responsible for certifying others): 
<br><dd>
<select name=user_id>
<option value=\"\"> -- Please select --
[db_html_select_value_options -select_option $user_id certifying_user "select 
user_id, first_names || ' ' || last_name as name 
from im_employees_active
order by lower(name)"]
</select>

<p><center>
<input type=submit value=\" $page_title \">
</center>
</p>

</form>

</blockquote>

"



doc_return  200 text/html [im_return_template]
