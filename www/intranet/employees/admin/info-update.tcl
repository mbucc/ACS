# /www/intranet/employees/admin/info-update.tcl

ad_page_contract {

    Allows admin to update an employees info

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date Jan 2000
    @cvs-id info-update.tcl,v 3.14.2.10 2000/09/22 01:38:34 kevin Exp
    @param user_id The user to edit 
    @param return_url Optional The url to return to
} {
    user_id 
    return_url:optional
}

ad_maybe_redirect_for_registration

if { ![db_0or1row get_user_info \
	"select u.first_names, u.last_name, u.bio, 
                info.featured_employee_blurb, info.featured_employee_approved_p
           from users u, im_employee_info info
           where u.user_id = info.user_id(+)
           and u.user_id = :user_id"] } {

    ad_return_error "Error" "That user doesn't exist"
    return
} 

set start_date [db_string gettoday "select sysdate from dual"]

db_release_unused_handles


set page_title "Edit \"$first_names $last_name\""
set context_bar [ad_context_bar_ws [list ./ "Employees"] [list view?[export_url_vars user_id] "One employee"] "Edit employee"]


doc_return  200 text/html "[im_header]
<form method=post action=info-update-2>
[export_form_vars return_url]
<input type=hidden name=dp.im_employee_info.user_id value=$user_id>

<table cellpadding=3>

<tr>
 <th align=right valign=top>Biography:</th>
 <td>
 <textarea name=dp.users.bio cols=40 rows=6 wrap=soft>[philg_quote_double_quotes $bio]</textarea>
 </td>
</tr>

<tr>
 <th align=right valign=top>Featured Employee Blurb:</th>
 <td>
 <textarea name=dp.im_employee_info.featured_employee_blurb cols=40 rows=6 wrap=soft>[philg_quote_double_quotes $featured_employee_blurb]</textarea>
 </td>
</tr>

<tr>
<th align=right valign=top>Blurb Approved?</th>
<td>
<input type=radio name=dp.im_employee_info.featured_employee_approved_p value=t[util_decode [value_if_exists featured_employee_approved_p] t " checked" ""]> Yes
<input type=radio name=dp.im_employee_info.featured_employee_approved_p value=f[util_decode [value_if_exists featured_employee_approved_p] t "" " checked"]>No
</td>
</tr>
</table>

<p>
<center>
<input type=submit value=Update>
</center>
</form>

[ad_footer]
"
