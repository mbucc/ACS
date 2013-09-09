# /admin/webmail/parse-errors-delete.tcl
# Written by Jin Choi <jsc@arsdigita.com> (2000-04-03)

ad_page_contract {
    Delete all rows in wm_parse_errors.
    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-04-03
    @cvs-id parse-errors-delete.tcl,v 1.2.6.3 2000/07/21 03:58:32 ron Exp
} {}

set db [ns_db gethandle]

ns_db dml $db "delete from wm_parse_errors"

ad_returnredirect "problems.tcl"
