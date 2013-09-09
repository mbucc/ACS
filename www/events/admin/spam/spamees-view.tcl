# spamees-view.tcl,v 1.1.2.2 2000/02/03 09:50:05 ron Exp
# events/admin/spamees-view.tcl
# Owner: bryanche@arsdigita.com
#####

ad_page_contract {
    Purpose: To show an admin about to spam a bunch of people a list
    of all the spamees.  

    @param sql_post_select sql query for which users to show

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id spamees-view.tcl,v 3.5.6.4 2000/09/22 01:37:42 kevin Exp
} {
    {sql_post_select:notnull}
}

if {![exists_and_not_null sql_post_select]} {
    ad_return_complaint 1 "<li>You have entered this page without
    a sql_post_select variable"
}

# we collect the page body in whole_page
set whole_page ""
append whole_page "[ad_admin_header "Spam"]

<h2>Spam</h2>

[ad_context_bar_ws [list "../index.tcl" "Events Administration"] [list "action-choose.tcl?[export_url_vars sql_post_select]" "Spam"] "Spamees"]

<hr>

You are spamming the following people:
<ul>
"


db_foreach evnt_spamees_view $sql_post_select {
    append whole_page "<li>$email"
}
append whole_page "</ul>[ad_footer]"

## clean up, return the page



doc_return  200 text/html $whole_page

##### EOF
