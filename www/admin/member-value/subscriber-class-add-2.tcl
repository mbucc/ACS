# /www/admin/member-value/subscriber-class-add-2.tcl

ad_page_contract {
    Add a new subscriber class into mv_monthly_rates table.
    @param subscriber_class 
    @param rate
    @param currency
    @author tony@arsdigita.com
    @creation-date Tue Jul 11 20:47:10 2000
    @cvs-id subscriber-class-add-2.tcl,v 1.1.2.7 2000/07/24 00:56:18 berkeley Exp

} {
    subscriber_class:notnull
    rate:notnull
    currency
}

if {[empty_string_p $currency]} {
    set currency "USD"
}

set errors ""
set err_cnt 0

set class_name_exists_p [db_0or1row mv_check_name_exists "select subscriber_class from mv_monthly_rates where subscriber_class=:subscriber_class"]

if {$class_name_exists_p == 1} {
    append errors " <li>The specified class name, $subscriber_class, already exists - please select another unique name"
    incr err_cnt
}

if {[string length $subscriber_class] > 30} {
    append errors " <li>Subscriber class name is limited to 30 characters only."
    incr err_cnt
}

if {![regexp {^[A-z][A-z][A-z]$} $currency]} {
    append errors " <li>Currency must contain 3 alphabets."
    incr err_cnt
}

if {![regexp {^([0-9]+)(\.)?([0-9]*)$} $rate]} {
    append errors " <li>Rate must be a positive number."
    incr err_cnt
}

if { ![empty_string_p $errors] } {
    ad_return_complaint $err_cnt "<ul>$errors</ul>"
    db_release_unused_handles
    return
}


db_dml mv_add_new_subscriber_class "insert into mv_monthly_rates (subscriber_class, rate, currency) values (:subscriber_class, :rate, :currency)" 

db_release_unused_handles

ad_returnredirect index

