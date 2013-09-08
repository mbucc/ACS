# /www/admin/member-value/index.tcl
ad_page_contract {
    Admin page for charging users or tracking down those who're imposing a burden on the community.
    
    @author mbryzek@arsdigita.com
    @creation-date Tue Jul 11 18:34:52 2000
    @cvs-id index.tcl,v 3.2.2.4 2000/09/22 01:35:31 kevin Exp

} {

}


set page_content "[ad_admin_header "Member Value Home for [ad_system_name]"]

<h2>Member Value (Money)</h2>

[ad_admin_context_bar "Member Value"]

<hr>

<ul>
<li>documentation: <a
href=\"/doc/member-value\">/doc/member-value</a>
<li>using real money? [util_PrettyTclBoolean [mv_parameter UseRealMoneyP]]
<li>charging monthly? [util_PrettyTclBoolean [mv_parameter ChargeMonthlyP]]
</ul>
"



if [mv_parameter ChargeMonthlyP 0] {
    # we have to do a monthly rate section
    append page_content "<h3>Monthly Rates</h3>\n<ul>\n"
    set sql "select mvmr.subscriber_class, mvmr.rate, count(user_id) as n_subscribers
    from mv_monthly_rates mvmr, users_payment up
    where mvmr.subscriber_class = up.subscriber_class(+)
    group by mvmr.subscriber_class, mvmr.rate
    order by mvmr.rate desc"
    db_foreach mv_subscriber_info_query $sql {
	append page_content "<li><a href=\"subscriber-class?subscriber_class=[ns_urlencode $subscriber_class]\">$subscriber_class</a> ($rate):  
<a href=\"subscribers-in-class?subscriber_class=[ns_urlencode $subscriber_class]\">$n_subscribers subscribers</a>\n"
    }
    append page_content "<p>\n<li><a href=\"subscriber-class-add\">create a new subscriber class</a>\n</ul>\n"    
}

append page_content "
<h3>Charges</h3>

<ul>
<li><a href=\"/admin/users/action-choose?expensive=1&include_accumulated_charges_p=1\">expensive users</a>

<p>

<li><a href=\"charges-all\">review all charges</a>
</ul>

"

if [mv_parameter UseRealMoneyP 0] {
    append page_content "
<h3>Billing</h3>

These are records of when we actually tried to bill users' credit
cards.

<ul>
"

    set sql "select mbs.*,round((success_time-start_time)*24*60) as n_minutes from mv_billing_sweeps mbs order by start_time desc"

    db_foreach mv_minutes_query $sql {
	append page_content "<li>$start_time: generated $n_orders orders;"
	if { $success_time == "" } {
	    append page_content "terminated prematurely"
	} else {
	    append page_content "terminated $n_minutes minutes later"
	}
    }

    append page_content "</ul>"
}

db_release_unused_handles

append page_content "[ad_admin_footer]"

doc_return  200 text/html $page_content

