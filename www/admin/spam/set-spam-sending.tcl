# www/admin/spam/set-spam-sending.tcl

ad_page_contract {

 Enable or disable the actual sending of email from the spam system.
 This is a way to halt the sending of any more email, if you need to.

    @param enable_p boolean (t or f) to enable or disable outgoing email
    @author hqm@arsdigita.com
    @cvs-id set-spam-sending.tcl,v 3.2.6.2 2000/07/21 03:58:01 ron Exp
} {
  enable_p
}


spam_set_email_sending $enable_p

ad_returnredirect "index.tcl"