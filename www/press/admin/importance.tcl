# /www/press/admin/importance.tcl

ad_page_contract {

    Change the importance setting for a group of press items

    @author  Ron Henderson (ron@arsdigita.com)
    @created Thu Sep 14 05:30:17 2000
    @cvs-id  importance.tcl,v 1.1.2.1 2000/09/16 19:07:21 ron Exp
} {
    press_items:notnull
    important_p:notnull
}

db_dml importance_update "
update press
set    important_p = :important_p
where  press_id in ([join $press_items ","])"

ad_returnredirect ""

