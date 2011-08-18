# $Id: one.tcl,v 3.0 2000/02/06 03:18:47 ron Exp $
set_the_usual_form_variables
# either category_id, subcategory_id, and/or subsubcategory_id
# OR categorization (list which contains category_id, subcategory_id, and/or subsubcategory_id)
# depending on how they got here

if { [info exists categorization] } {
    catch { set category_id [lindex $categorization 0] }
    catch { set subcategory_id [lindex $categorization 1] }
    catch { set subsubcategory_id [lindex $categorization 2] }
}

# now we're left with category_id, subcategory_id, and/or subsubcategory_id
# regardless of how we got here
if { ![info exists category_id] } {
    set category_id ""
}
if { ![info exists subcategory_id] } {
    set subcategory_id ""
}
if { ![info exists subsubcategory_id] } {
    set subsubcategory_id ""
}

set db [ns_db gethandle]
set mailing_list_name [ec_full_categorization_display $db $category_id $subcategory_id $subsubcategory_id]

ReturnHeaders
ns_write "[ad_admin_header "$mailing_list_name"]

<h2>$mailing_list_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Mailing Lists"] "One Mailing List"]

<hr>
<h3>Members</h3>
<ul>
"

set user_query "select u.user_id, first_names, last_name
    from users u, ec_cat_mailing_lists m
    where u.user_id=m.user_id
    "

if { ![empty_string_p $subsubcategory_id] } {
    append user_query "and m.subsubcategory_id=$subsubcategory_id"
} elseif { ![empty_string_p $subcategory_id] } {
    append user_query "and m.subcategory_id=$subcategory_id
    and m.subsubcategory_id is null"
} elseif { ![empty_string_p $category_id] } {
    append user_query "and m.category_id=$category_id
    and m.subcategory_id is null"
} else {
    append user_query "and m.category_id is null"
}

set selection [ns_db select $db $user_query]

set n_users 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr n_users
    ns_write "<li><a href=\"/admin/users/one.tcl?user_id=$user_id\">$first_names $last_name</a> \[<a href=\"member-remove.tcl?[export_url_vars category_id subcategory_id subsubcategory_id user_id]\">remove</a>\]"
}

if { $n_users == 0 } {
    ns_write "None"
}

ns_write "</ul>

<h3>Add a Member</h3>

<form method=post action=member-add.tcl>
[export_form_vars category_id subcategory_id subsubcategory_id]
By last name: <input type=text name=last_name size=30>
<input type=submit value=\"Search\">
</form>

<form method=post action=member-add.tcl>
[export_form_vars category_id subcategory_id subsubcategory_id]
By email address: <input type=text name=email size=30>
<input type=submit value=\"Search\">
</form>

[ad_admin_footer]
"