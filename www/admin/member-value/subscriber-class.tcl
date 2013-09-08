# /www/admin/member-value/subscriber-class.tcl

ad_page_contract {
    Allows the user to view/edit/delete the subscriber class.

    @author mbryzek@arsdigita.com
    @creation-date Tue Jul 11 19:43:26 2000
    @cvs-id subscriber-class.tcl,v 3.1.6.7 2000/09/22 01:35:32 kevin Exp

} {
    subscriber_class:notnull
}

set page_content "[ad_admin_header "$subscriber_class"]

<h2>$subscriber_class</h2>

[ad_admin_context_bar [list "" "Member Value"] "Subscriber class"]


<hr>

<ul>

"

db_1row mv_rate_query "select rate, currency from mv_monthly_rates where subscriber_class = :subscriber_class"

db_release_unused_handles

append page_content "<li><form method=get action=\"subscriber-class-new-rate-currency\">
[export_form_vars subscriber_class]
Rate:
<input type=text size=7 name=rate value=\"$rate\">
<li>Currency:
<input type=text size=7 name=currency value=\"$currency\">
<p>
<input type=submit value=\"Set\">
</form>

</ul>

If you decide that this subscriber class isn't working anymore, you can 
<a href=\"subscriber-class-delete?subscriber_class=[ns_urlencode $subscriber_class]\">delete it and move all the subscribers into another class</a>.

[ad_admin_footer]
"
doc_return  200 text/html $page_content
