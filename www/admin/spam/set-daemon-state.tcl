# set-daemon-state.tcl
#
# hqm@arsdigita.com
#
# enable or disable the dropzone scanner daemon
#

# form vars:
# enable_p      enable or disable outgoing email 

set_the_usual_form_variables

spam_set_daemon_active $enable_p

ad_returnredirect "index.tcl"