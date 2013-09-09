# www/admin/spam/set-daemon-state.tcl
#
ad_page_contract {

  Enable or disable the dropzone scanner daemon.

    @param enable_p boolean (t or f) to enable or disable outgoing email
    @author hqm@arsdigita.com
    @cvs-id set-daemon-state.tcl,v 3.2.6.3 2000/07/21 03:58:01 ron Exp
} {
  enable_p
}

spam_set_daemon_active $enable_p

ad_returnredirect "index.tcl"