# /www/intranet/customers/primary-contact-users.tcl

ad_page_contract {
    Allows you to have a primary contact that references the users
    table. We don't use this yet, but it will indeed be good once all
    customers are in the users table

    @param group_id group id of the customer

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000
    @cvs-id primary-contact-users.tcl,v 3.7.2.9 2000/09/22 01:38:28 kevin Exp

} {
    group_id:integer
    
}

set user_id [ad_maybe_redirect_for_registration]

# Avoid hardcoding the url stub
set target "[im_url_stub]/customers/primary-contact-users-2"

set customer_name [db_string customer_name \
	"select g.group_name
           from im_customers c, user_groups g
          where c.group_id = :group_id
            and c.group_id=g.group_id"]

db_release_unused_handles

set page_title "Select primary contact for $customer_name"
set context_bar [ad_context_bar_ws [list ./ "Customers"] [list view?[export_url_vars group_id] "One customer"] "Select contact"]

set page_body "

Locate your new primary contact by

<form method=get action=/user-search>
[export_form_vars group_id target limit_to_users_in_group_id]
<input type=hidden name=passthrough value=group_id>

<table border=0>
<tr><td>Email address:<td><input type=text name=email size=40></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>

<p>

<center>
<input type=submit value=Search>
</center>
</form>

"

doc_return  200 text/html [im_return_template]
