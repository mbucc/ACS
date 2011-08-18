# $Id: add-comments.tcl,v 3.0 2000/02/06 03:25:20 ron Exp $
# called from ../users/one-user-specific-objects.tcl

set_form_variables

# check arguments -----------------------------------------------------

# it is not clear to me whey we have one object_name argument here
# of the format OWBER.TABLE_NAME that needs to be parsed, rather than 
# two seperate arguments?

# $object_type   REQUIRED ARGUMENT
if { ![info exists object_name] } {
    ns_returnerror 500 "Missing \$object_name (format: OWBER.TABLE_NAME)"
    return
}
set object_info [split $object_name .]
set owner [lindex $object_info 0]
set object_name [lindex $object_info 1]


# check parameter to see if we want to display SQL as comments
# actually harcoded now during development, but will use ns_info later

set show_sql_p "t"

# arguments OK, get database handle, start building page ----------------------------------------

set page_name "Add or update comments on table $owner.$object_name"
ReturnHeaders
set db [cassandracle_gethandle]
ns_write "
[ad_admin_header $page_name]
<h2>$page_name</h2>
[ad_admin_context_bar [list "../users/index.tcl" "Users"] [list "../users/user-owned-objects.tcl" "Object Ownership"] [list "../users/one-user-specific-objects.tcl?owner=$owner&object_type=TABLE" "Tables"] [list "describe-table.tcl?object_name=$owner.$object_name" "One Table"] "Add comment"]
<!-- version 1.1, 1999-10-25, Dave Abercrombie, abe@arsdigita.com -->
<hr>
"

# begin form ------------------------------------------------------------------------------------
ns_write "
<form method=post action=\"add-comments-2.tcl\">
<input type=hidden name=object_name value=$owner.$object_name>
<p>
"


# we do two seperate queries: one for the table (0 or 1)
# and one for the columns (0, 1, or many)
# note that these same queries are similar to 
# those run in /objects/describe-table.tcl, excpet
# I do not have the not null conditions

set table_comment_query "
-- /objects/add-comments.tcl
-- get table comments
-- 
select
     dtc.comments as table_comment
from
     DBA_TAB_COMMENTS dtc
where
     dtc.owner='$owner' 
and  dtc.table_name='$object_name'
     -- do NOT need to make sure there really is a comment
-- and  dtc.comments is not null
"
if { [string compare $show_sql_p "t" ]==0 } {
    ns_write "<!-- $table_comment_query -->\n"
}

set column_comment_query "
-- /objects/add-comments.tcl
-- get column comments
select
     dtc.column_id,
     dtc.column_name,
     dcc.comments as column_comment
from
     DBA_COL_COMMENTS dcc,
     dba_tab_columns dtc
where
     -- join dtc to dcc
     -- dtc is getting involved so I can order by column_id
     dcc.owner = dtc.owner
and  dcc.table_name = dtc.table_name
and  dcc.column_name = dtc.column_name
     -- specify table to dcc
and  dcc.owner='$owner'
and  dcc.table_name='$object_name'
     -- specify table to dtc
     -- this is obviuosly redundant (given the join),
     -- but it helps performance on these Oracle 
     -- data dictionary views
and  dtc.owner='$owner'
and  dtc.table_name='$object_name'
     -- do NOT need to make sure there really is a comment
-- and  dcc.comments is not null
order by 
     dtc.column_id
"
if { [string compare $show_sql_p "t" ]==0 } {
    ns_write "<!-- $column_comment_query -->\n"
}


# run table query (already have db handle) 
# deal with nulls (is this necessary?)
set selection [ns_db 0or1row $db $table_comment_query]
if {[string compare $selection ""]!=0 } {
    set_variables_after_query
} else {
    set table_comment ""
}
# write user input text box for table comment
# need to quote value arg in case it contains spaces
ns_write "
<p>Table: $object_name <input type=submit value=\"update all\"></p><textarea cols=40 rows=6 name=\"table_comment\" wrap=VIRTUAL value=\"$table_comment\">$table_comment</textarea>
"

# run column query (already have db handle) 
# and output rows as form text areas with comuted names
# I create variable names like "columnComment_1", etc.
# so the "...-2" page needs to know about this format
set selection [ns_db select $db $column_comment_query]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "
    <p>Column $column_id: $column_name <input type=submit value=\"update all\"></p><textarea cols=40 rows=6 name=\"columnComment_$column_id\" wrap=VIRTUAL value=\"$column_comment\">$column_comment</textarea>
    "
}

# close up form --------------------------------------------------------------------
ns_write "
</form>
"


# close up page --------------------------------------------------------------------
ns_write "
[ad_admin_footer]
"