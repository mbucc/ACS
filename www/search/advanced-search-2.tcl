# /www/search/advanced-search-2.tcl

ad_page_contract {
    Sets user search preferences
    
    @author phong@arsdigita.com
    @creation-date 2000-08-01
    @cvs-id advanced-search-2.tcl,v 1.1.2.1 2000/08/25 23:58:39 phong Exp
} { 
    {display "by_section"}
    {num_results 50}
    { search "Search" }
    query_string:optional
    sections:multiple,optional
    {save 0}
}

if { $save == 1 } {
    ad_set_client_property -browser t -persistent t "search" "display_by_section_or_one_list" $display
    ad_set_client_property -browser t -persistent t "search" "num_of_results_to_display" $num_results
}

# create a string to export sections list
set sections_string ""
foreach s $sections {
    append sections_string "&sections=$s"
}

ad_returnredirect "search?[export_url_vars query_string]$sections_string"

