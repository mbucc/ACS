# $Id: set-spam-sending.tcl,v 3.1.2.1 2000/04/28 15:09:21 carsten Exp $
# set-spam-sending.tcl
#
# hqm@arsdigita.com
#
# enable or disable the actual sending of email from the spam system.
# This is a way to halt the sending of any more email, if you need to.
#

# form vars:
# enable_p      enable or disable outgoing email 

set_the_usual_form_variables

spam_set_email_sending $enable_p

ad_returnredirect "index.tcl"