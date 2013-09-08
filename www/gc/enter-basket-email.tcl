# /www/gc/enter-basket-email.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id enter-basket-email.tcl,v 3.2.6.3 2000/09/22 01:37:53 kevin Exp
} {
    ad_id:integer
}

doc_return  200 text/html "<html>
<head>
<title>Enter Email Address</title>
</head>
<body bgcolor=#ffffff text=#000000>
<h2>Enter Email Address</h2>

<p>
We need your email address before we can build you a shopping basket.

<form method=POST action=enter-basket-email-final>
<input type=hidden name=ad_id value=$ad_id>
Your full Internet email address: <input type=text name=email size=30>
</form>
<p>
[gc_footer [gc_system_owner]]
"
