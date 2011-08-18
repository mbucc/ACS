# $Id: bulkmail-mailer.tcl,v 3.0.4.1 2000/04/28 15:09:20 carsten Exp $
# bulkmail-mailer.tcl
#
# hqm@arsdigita.com
#
# enable or disable the use of bulkmail module for sending of email from the spam system.
#
# If disabled, we revert to ns_sendmail (slower, and no bounce handling)
#

# form vars:
# enable_p      enable or disable outgoing user of bulkmail

set_the_usual_form_variables

spam_set_use_bulkmail_p $enable_p

ad_returnredirect "index.tcl"