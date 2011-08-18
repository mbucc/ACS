# $Id: run-spam-daemon.tcl,v 3.0 2000/02/06 03:30:08 ron Exp $
# run-spam-daemon.tcl
#
# hqm@arsdigita.com
#
# manually invoke the spam daemon (it is normally scheduled to run once an hour)
#

ReturnHeaders


ns_write "[ad_admin_header "Invoke Spam Daemon Manually "]

<h2>Invoking spam daemon manually</h2>

[ad_admin_context_bar [list "index.tcl" "Spam"] "Manually Run Spam Daemon"]


<hr>
<p>

"


ns_write "Invoking send_scheduled_spam_messages interactively.
<p>This may run for a long time if one or more large jobs are queued...
<p>
<pre>"

send_scheduled_spam_messages

ns_write "</pre>
Done.
<p>
<a href=index.tcl>Return to spam admin index page</a>
[ad_admin_footer]

"