#  www/admin/ecommerce/user-classes/add.tcl
ad_page_contract {
    @param user_class_name

  @author
  @creation-date
  @cvs-id add.tcl,v 3.1.6.6 2001/01/12 19:35:03 khy Exp
} {
    user_class_name:trim,notnull
}

set page_html "[ad_admin_header "Confirm New User Class"]

<h2>Confirm New User Class</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "User Classes"] "Confirm New User Class"]

<hr>

Add the following new user class?

<blockquote>
<code>$user_class_name</code>
</blockquote>
"


set user_class_id [db_string get_uc_id_seq "select ec_user_class_id_sequence.nextval from dual"]

append page_html "<form method=post action=add-2>
[export_form_vars user_class_name]
[export_form_vars -sign user_class_id]
<center>
<input type=submit value=\"Yes\">
</center>
</form>

[ad_admin_footer]
"


doc_return  200 text/html $page_html