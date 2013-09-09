# /www/intranet/users/office-update.tcl

ad_page_contract {
    Purpose: Let's a user manage the office s/he's in

    @param return_url

    @author mbryzek@arsdigita.com
    @creation-date 4/4/2000

    @cvs-id office-update.tcl,v 3.5.6.8 2000/09/22 01:38:51 kevin Exp
} {
    { return_url "" }
}

set user_id [ad_maybe_redirect_for_registration]


set office_group_id [im_office_group_id]
set query "select   ug.group_name, ug.group_id, ad_group_member_p ( :user_id, ug.group_id ) as belongs_to_group_p
           from     im_offices o, user_groups ug
           where    o.group_id=ug.group_id and 
                    ug.parent_group_id=:office_group_id
           order by lower(ug.group_name)"

set results ""
db_foreach user_groups_select $query {
    append results "  <br><input type=checkbox name=group_id value=$group_id[util_decode $belongs_to_group_p "t" " checked" ""]> $group_name\n"
} 

if { [empty_string_p $results] } {
    ad_return_error "Error: no offices" "There are currently no offices in the system. You can <a href=../offices/ae>create</a> a new office."
    return
}

set page_title [db_string first_last_name \
	"select first_names || ' ' || last_name from users where user_id=:user_id"]

set context_bar [ad_context_bar_ws [list "./" "Users"] [list view?[export_url_vars user_id] "One user"] "Update office info"]

set page_body "

Simply check the office (or offices) to which you belong:
<p>
<form method=post action=office-update-2>
[export_form_vars return_url]
<ul>
$results
<p><input type=submit value=\" Save office information \">
</ul>
</form>
"



doc_return  200 text/html [im_return_template]

