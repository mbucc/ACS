# www/admin/spam/bulkmail-mailer.tcl

ad_page_contract {

 Force spam into a specific state.

    @param enable_p boolean (t or f) to enable or disable use of bulkmailer module for sending mail
    @author hqm@arsdigita.com
    @cvs-id bulkmail-mailer.tcl,v 3.1.6.2 2000/07/21 03:57:59 ron Exp
} {
   enable_p
}


spam_set_use_bulkmail_p $enable_p

ad_returnredirect "index.tcl"



