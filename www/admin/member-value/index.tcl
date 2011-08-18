# $Id: index.tcl,v 3.0 2000/02/06 03:24:59 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Member Value Home for [ad_system_name]"]

<h2>Member Value (Money)</h2>

[ad_admin_context_bar "Member Value"]

<hr>

<ul>
<li>documentation: <a
href=\"/doc/member-value.html\">/doc/member-value.html</a>
<li>using real money? [util_PrettyTclBoolean [mv_parameter UseRealMoneyP]]
<li>charging monthly? [util_PrettyTclBoolean [mv_parameter ChargeMonthlyP]]
</ul>

"

set db [ns_db gethandle]


if [mv_parameter ChargeMonthlyP 0] {
    # we have to do a monthly rate section
    ns_write "<h3>Monthly Rates</h3>\n<ul>\n"
    set selection [ns_db select $db "select mvmr.subscriber_class, mvmr.rate, count(user_id) as n_subscribers
from mv_monthly_rates mvmr, users_payment up
where mvmr.subscriber_class = up.subscriber_class(+)
group by mvmr.subscriber_class, mvmr.rate
order by mvmr.rate desc"]
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	ns_write "<li><a href=\"subscriber-class.tcl?subscriber_class=[ns_urlencode $subscriber_class]\">$subscriber_class</a> ($rate):  
<a href=\"subscribers-in-class.tcl?subscriber_class=[ns_urlencode $subscriber_class]\">$n_subscribers subscribers</a>\n"
    }
    ns_write "<p>\n<li><a href=\"/NS/Db/GetEntryForm/main/mv%5fmonthly%5frates\">create a new subscriber class</a>\n</ul>\n"
    
}

ns_write "
<h3>Charges</h3>

<ul>
<li><a href=\"/admin/users/action-choose.tcl?expensive=1&include_accumulated_charges_p=1\">expensive users</a>

<p>


<li><a href=\"charges-all.tcl\">review all charges</a>
</ul>

"

if [mv_parameter UseRealMoneyP 0] {
    ns_write "
<h3>Billing</h3>

These are records of when we actually tried to bill users' credit
cards.

<ul>
"

    set selection [ns_db select $db "select mbs.*,round((success_time-start_time)*24*60) as n_minutes from mv_billing_sweeps mbs order by start_time desc"]

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	ns_write "<li>$start_time: generated $n_orders orders;"
	if { $success_time == "" } {
	    ns_write "terminated prematurely"
	} else {
	    ns_write "terminated $n_minutes minutes later"
	}
    }

    ns_write "
</ul>
"
}

ns_write "[ad_admin_footer]
"
