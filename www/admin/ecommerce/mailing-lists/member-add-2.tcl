# $Id: member-add-2.tcl,v 3.0.4.1 2000/04/28 15:08:42 carsten Exp $
set_the_usual_form_variables
# user_id, category_id, subcategory_id, subsubcategory_id

# we need them to be logged in
set admin_user_id [ad_verify_and_get_user_id]

if {$admin_user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

if { ![info exists subcategory_id] || [empty_string_p $subcategory_id] } {
    set check_string "select count(*) from ec_cat_mailing_lists where user_id=$user_id and category_id=$category_id and subcategory_id is null"
    set insert_string "insert into ec_cat_mailing_lists (user_id, category_id) values ($user_id, $category_id)"
} elseif { ![info exists subsubcategory_id] || [empty_string_p $subsubcategory_id] } {
    set check_string "select count(*) from ec_cat_mailing_lists where user_id=$user_id and subcategory_id=$subcategory_id and subsubcategory_id is null"
    set insert_string "insert into ec_cat_mailing_lists (user_id, category_id, subcategory_id) values ($user_id, $category_id, $subcategory_id)"
} elseif { [info exists subsubcategory_id] && ![empty_string_p $subsubcategory_id] } {
    set check_string "select count(*) from ec_cat_mailing_lists where user_id=$user_id and subsubcategory_id=$subsubcategory_id"
    set insert_string "insert into ec_cat_mailing_lists (user_id, category_id, subcategory_id, subsubcategory_id) values ($user_id, $category_id, $subcategory_id, $subsubcategory_id)"
} else {
    set check_string "select count(*) from ec_cat_mailing_lists where user_id=$user_id and category_id is null"
    set insert_string "insert into ec_cat_mailing_lists (user_id) values ($user_id)"
}

if { [database_to_tcl_string $db $check_string] == 0 } {
    ns_db dml $db $insert_string
}

ad_returnredirect "one.tcl?[export_url_vars category_id subcategory_id subsubcategory_id]"
