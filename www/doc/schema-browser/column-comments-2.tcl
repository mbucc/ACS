set_the_usual_form_variables

#
# expected: table_name, column_name, comments
#

set db [ns_db gethandle]

ns_db dml $db "comment on column $table_name.$column_name is '$QQcomments'"

ad_returnredirect "index.tcl?[export_url_vars table_name]"