# /www/intranet/user-search.tcl

ad_page_contract {
    Purpose: Standard form to search for a user (through /user-search.tcl)

    @param target Where to link to.
    @param passthrough What to pass on.

    @author mbryzek@arsdigita.com
    @creation-date Mar 2000

    @cvs-id user-search.tcl,v 3.7.2.6 2000/09/22 01:38:22 kevin Exp
} {
    target
    passthrough    
}

set user_id [ad_maybe_redirect_for_registration]

set page_title "Search for a user"
set context_bar [ad_context_bar_ws [list ./ "Intranet"] "User search"]

set page_body "

Locate user by:

<form method=get action=/user-search>
[export_ns_set_vars form]

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
