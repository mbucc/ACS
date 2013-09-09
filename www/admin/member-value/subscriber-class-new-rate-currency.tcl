# /www/admin/member-value/subscriber-class-new-rate-currency.tcl

ad_page_contract {
    Change rate and currency for the subscriber class.
    @param rate
    @param currency
    @param subscriber_class
    @author tony@arsdigita.com
    @creation-date Wed Jul 19 17:59:42 2000
    @cvs-id subscriber-class-new-rate-currency.tcl,v 1.1.2.3 2000/07/23 23:46:54 berkeley Exp

} {
    subscriber_class:notnull
    rate:notnull
    currency:notnull
}

set errors ""
set err_cnt 0

if {![regexp {^[A-z][A-z][A-z]$} $currency]} {
    append errors " <li>Currency must contain 3 alphabets."
    incr err_cnt
}

if {![regexp {^([0-9]+)(\.)?([0-9]*)$} $rate]} {
    append errors " <li>Rate must be a number."
    incr err_cnt
}

if { ![empty_string_p $errors] } {
    ad_return_complaint $err_cnt "<ul>$errors</ul>"
    return
}

db_dml mv_update_rate_currency { update mv_monthly_rates set rate = :rate, currency = :currency where subscriber_class = :subscriber_class }

db_release_unused_handles

ad_returnredirect index