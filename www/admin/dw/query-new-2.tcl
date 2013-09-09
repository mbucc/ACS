#/www/dw/query-new-2.tcl

ad_page_contract {
    Insert query name into query table

    @author Philip Greenspun (philg@mit.edu)
    @creation-date ?

    @param query_name name of the new query
    @cvs-id query-new-2.tcl,v 1.1.2.1 2000/08/09 14:45:18 richardl Exp
} {
    {query_name:trim,notnull}
}

set user_id [ad_maybe_redirect_for_registration]

set query_id [db_string dw_get_next_query_id {select query_sequence.nextval from dual}]

db_dml dw_insert_new_query {insert into queries (query_id, query_name, query_owner, definition_time)
values (:query_id, :query_name, :user_id, sysdate)}

db_release_unused_handles
ad_returnredirect "query.tcl?query_id=$query_id"


