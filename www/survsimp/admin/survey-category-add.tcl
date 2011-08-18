ad_page_variables {survey_id category}

if {[empty_string_p $QQcategory]} {
    ad_return_complaint 1 "You did not enter a category name."
    return
}

set db [ns_db gethandle]

ns_db dml $db "begin transaction"

set category_id [database_to_tcl_string $db "select 
category_id_sequence.nextval from dual"]

ns_db dml $db "insert into categories (category_id, category,category_type)
values ($category_id, '$QQcategory', 'survsimp')"

ns_db dml $db "insert into site_wide_category_map (map_id, category_id,
on_which_table, on_what_id, mapping_date, one_line_item_desc) 
values (site_wide_cat_map_id_seq.nextval, $category_id, 'survsimp_surveys',
$survey_id, sysdate, 'Survey')"

ns_db dml $db "end transaction"

ad_returnredirect "one.tcl?[export_url_vars survey_id]"

