# $Id: enter-basket-email.tcl,v 3.1 2000/03/10 23:58:26 curtisg Exp $
set_form_variables

# ad_id is the only interesting one

ns_return 200 text/html "<html>
<head>
<title>Enter Email Address</title>
</head>
<body bgcolor=#ffffff text=#000000>
<h2>Enter Email Address</h2>

<p>
We need your email address before we can build you a shopping basket.

<form method=POST action=enter-basket-email-final.tcl>
<input type=hidden name=ad_id value=$ad_id>
Your full Internet email address: <input type=text name=email size=30>
</form>
<p>
[gc_footer [gc_system_owner]]
"
