# /www/admin/adserver/add-adv-group-2.tcl

ad_page_contract {
    target page for ad-adv-group.tcl
    
    @param group_key:notnull
    @param pretty_name
    @param rotation_method

    @author modified 07/13/200 by mchu@arsdigita.com
    @cvs-id add-adv-group-2.tcl,v 3.1.6.7 2000/11/20 23:55:14 ron Exp
} {
    group_key:notnull,trim
    pretty_name:trim
    rotation_method
}

db_dml adv_insert_query "
insert into adv_groups 
(group_key, pretty_name, rotation_method)
select :group_key, :pretty_name, :rotation_method
from dual
where not exists (select 1 from adv_groups where group_key = :group_key)"

# The handling of '' and null in Oracle is too weird to do this in the query
if { [empty_string_p $pretty_name] } {
    set pretty_name_sql "pretty_name is null"
} else {
    set pretty_name_sql "pretty_name = :pretty_name"
}
# The trim around rotation_method is necessary since it is a CHAR column,
# not a VARCHAR
set insert_succ_p [db_string adv_insert_check "select count(*) from adv_groups 
  where group_key = :group_key and $pretty_name_sql
        and trim(rotation_method) = :rotation_method" ]
db_release_unused_handles

if { $insert_succ_p } {
    ad_returnredirect "one-adv-group?[export_url_vars group_key]"
} else {
    doc_return 200 text/html "[ad_admin_header "Adding group failed"]
    <h2>Adding group failed</h2>
    [ad_admin_context_bar [list "" "AdServer"] "New Ad Group"]
    <hr>
    <p> Insert_succ_p $insert_succ_p: /$group_key/$pretty_name/$rotation_method/
    <p> We are sorry. The group <i>$group_key</i> could not be added. There already is a
    group with the same group name. 
    <p> Please use the back button on your browser and change the group name.

    [ad_footer]"
}


