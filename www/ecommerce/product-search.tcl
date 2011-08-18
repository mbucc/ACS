# $Id: product-search.tcl,v 3.1 2000/03/07 03:47:47 eveander Exp $
# this page searches for products either within a category (if specified) or
# within all products

set_the_usual_form_variables
# search_text
# possibly category_id usca_p

if { ![info exists category_id] } {
    set category_id ""
}

set user_id [ad_verify_and_get_user_id]

# user session tracking
set user_session_id [ec_get_user_session_id]

set db_pools [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]

# user sessions:
# 1. get user_session_id from cookie
# 2. if user has no session (i.e. user_session_id=0), attempt to set it if it hasn't been
#    attempted before
# 3. if it has been attempted before,
#    (a) if they have no offer_code, then do nothing
#    (b) if they have a offer_code, tell them they need cookies on if they
#        want their offer price
# 4. Log this category_id, search_text into the user session

ec_create_new_session_if_necessary [export_url_vars category_id search_text] cookies_are_not_required
# type6

if { [string compare $user_session_id "0"] != 0 } {
    ns_db dml $db "insert into ec_user_session_info (user_session_id, category_id, search_text) values ($user_session_id, [ns_dbquotevalue $category_id integer], '[DoubleApos $search_text]')"
}


if { ![empty_string_p $category_id] } {
    set category_name [database_to_tcl_string $db "select category_name from ec_categories where category_id=$category_id"]
} else {
    set category_name ""
}

if { ![empty_string_p $category_id] } {
    set selection [ns_db select $db "select p.product_name, p.product_id, p.dirname, p.one_line_description,pseudo_contains(p.product_name || p.one_line_description || p.detailed_description || p.search_keywords, '[DoubleApos $search_text]') as score
    from ec_products_searchable p, ec_category_product_map c
    where c.category_id=$category_id
    and p.product_id=c.product_id
    and pseudo_contains(p.product_name || p.one_line_description ||  p.detailed_description || p.search_keywords, '[DoubleApos $search_text]') > 0
    order by score desc"]
} else {
    set selection [ns_db select $db "select p.product_name, p.product_id, p.dirname, p.one_line_description,pseudo_contains(p.product_name || p.one_line_description || p.detailed_description || p.search_keywords, '[DoubleApos $search_text]') as score
    from ec_products_searchable p
    where pseudo_contains(p.product_name || p.one_line_description ||  p.detailed_description || p.search_keywords, '[DoubleApos $search_text]') > 0
    order by score desc"]
}

set search_string ""
set search_count 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr search_count

    append search_string "<table width=90%>
<tr>
<td valign=center>
 <table>
 <tr><td><a href=\"product.tcl?[export_url_vars product_id]\">$product_name</a></td></tr>
 <tr><td>$one_line_description</td></tr>
 <tr><td>[ec_price_line $db_sub $product_id $user_id ""]</td></tr>
 </table>
</td>
<td align=right valign=top>[ec_linked_thumbnail_if_it_exists $dirname "t" "t"]</td>
</tr>
</table>
"
}

if { $search_count == 0 } {
    set search_results "No products found."
} else {
    set search_results " $search_count item[ec_decode $search_count "1" "" "s"] found.<p>$search_string"
}

ad_return_template
