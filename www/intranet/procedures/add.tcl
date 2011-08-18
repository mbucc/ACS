# $Id: add.tcl,v 3.2.2.1 2000/03/17 08:02:22 mbryzek Exp $
# File: /www/intranet/procedures/add.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: Form to enter necessary info about a new procedure
#

ad_maybe_redirect_for_registration
set user_id [ad_get_user_id]

set db [ns_db gethandle]
set procedure_id [database_to_tcl_string $db \
	"select im_procedures_procedure_id_seq.nextval from dual"]

set page_title "Add a procedure"
set context_bar [ad_context_bar [list "/" Home] [list "../index.tcl" "Intranet"] [list "index.tcl" "Procedures"] "Add procedure"]

set page_body "
<blockquote>

<form method=post action=add-2.tcl>
<input type=hidden name=procedure_id [export_form_value procedure_id]>

[im_format_number 1] The procedure:
<br><dd><input type=text size=50 maxlength=200 name=name [export_form_value name]>

<p>[im_format_number 2] Notes on the procedure:
<br><dd><textarea name=note cols=50 rows=8 wrap=soft>[philg_quote_double_quotes [value_if_exists note]]</textarea>

<p>[im_format_number 3] The first person certified to do the procedure (and the
person responsible for certifying others): 
<br><dd>
<select name=user_id>
<option value=\"\"> -- Please select --
[ad_db_optionlist $db "select 
first_names || ' ' || last_name as name, user_id 
from users
where ad_group_member_p ( user_id, [im_employee_group_id] ) = 't'
order by lower(name)" [value_if_exists creation_user]]
</select>

<p><center>
<input type=submit value=\" $page_title \">
</center>
</p>

</form>

</blockquote>

"

ns_return 200 text/html [ad_partner_return_template]