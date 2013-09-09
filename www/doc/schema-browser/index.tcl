ad_page_contract {    
    data structures used

    column_info: a type of ns_set expected to containt the following values
    column_name
    data_type
    data_length
    column_comments
    constraint_list -- list of ids of constraint_info ns_sets
    data_default
    nullable
    

    constraint_info: a type of ns_set expected to containt the following values:
    constraint_name 
    constraint_type 
    constraint_columns -- list of column names
    search_condition -- optional -- not null and check constraint types only
    foreign_columns -- list of foreign column names -- optional -- foreign constraints only
    foreign_table -- optional -- foreign constraints only
    foreign_constraint  -- optional -- foreign constraints only
    r_constraint_name -- optional -- foreign constraints only

    @param table_name
    
    @author mark@ciccarello.com
    @creation-date ?
    @cvs-id index.tcl,v 1.8.2.7 2000/09/22 01:37:25 kevin Exp
} {
    table_name:optional
}

# -----------------------------------------------------------------------------


set page_content "[ad_header "[ad_system_name] Schema Browser"]

<h2>[ad_system_name] Schema Browser</h2>
[ad_context_bar_ws "Schema Browser"]
<hr>
"

if { [exists_and_not_null table_name] } {
    append page_content [util_memoize "sb_get_table_description $table_name"]
} else {
    set table_name ""
}

append page_content "<h3>Tables:</h3>
[sb_get_tables $table_name]
[ad_footer]"

doc_return  200 text/html $page_content



    

