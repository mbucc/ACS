#/www/dw/query-edit-sql.tcl
ad_page_contract {
    Edit the SQL query by hand

    @author Philip Greenspun
    @creation-date 
    @param query_id an unique id identifies query
    @cvs-id query-edit-sql.tcl,v 1.1.2.2 2000/09/22 01:34:44 kevin Exp

} {
    {query_id:naturalnum,notnull}
}

set selection [db_0or1row dw_query_edit_sql_get_query_name {select query_name, 
                                           definition_time, 
                                           query_sql, 
                                           first_names || ' ' || last_name as query_owner 
                                    from   queries, users
                                    where  query_id = :query_id
                                           and    query_owner = users.user_id}]

if {$selection == 0} {
    ad_return_error "Invalid query id"  "Invalid query id or this user doesn't own this query."
    db_release_unused_handles
    return
}

append page_content "
[ad_header "Hand editing SQL for [ns_quotehtml $query_name]"]

<h2>Hand editing SQL</h2>

for <a href=\"query?query_id=$query_id\">[ns_quotehtml $query_name]</a> 
defined by $query_owner on [util_IllustraDatetoPrettyDate $definition_time]

<hr>
"

if [empty_string_p $query_sql] {
    # this is the first time the user has hand-edited the SQL; generate it
    set query_info [dw_build_sql $query_id]
    set query_sql [lindex $query_info 0]
} 

append page_content "
<form method=POST action=\"query-edit-sql-2\">
[export_form_vars query_id]
<textarea name=query_sql rows=10 cols=70>
$query_sql
</textarea>

<br>
<br>
<center>
<input type=submit value=\"Update\">
</center>
</form>
"

if { [db_string dw_query_edit_sql_find_query "select count(*) from query_columns where query_id = :query_id"] > 0 } {
    append page_content "<p>

If you wish to go back to the automatically generated query, you can
<a href=\"query-delete-sql?query_id=$query_id\">delete this
hand-edited SQL</a>.
"
}

append page_content "[ad_footer]"


doc_return  200 text/html $page_content






