# www/admin/spam/send-spam-now.tcl

ad_page_contract {

  Manually force spam daemon to scan queue to send any scheduled messages

    @author hqm@arsdigita.com
    @cvs-id send-spam-now.tcl,v 3.0.12.5 2000/09/22 01:36:06 kevin Exp
} {
}



doc_return  200 text/html  "running spam queue
[send_scheduled_spam_messages]
<p>done
"


