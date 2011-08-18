# $Id: subscriber-class-new-currency.tcl,v 3.0.4.1 2000/04/28 15:09:10 carsten Exp $
set_the_usual_form_variables

# subscriber_class, currency

set db [ns_db gethandle]

ns_db dml $db "update mv_monthly_rates set currency = '$QQcurrency' where subscriber_class = '$QQsubscriber_class'"

ad_returnredirect "subscriber-class.tcl?subscriber_class=[ns_urlencode $subscriber_class]"
