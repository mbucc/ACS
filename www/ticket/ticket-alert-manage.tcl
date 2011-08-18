# $Id: ticket-alert-manage.tcl,v 3.0.4.1 2000/04/28 15:11:35 carsten Exp $
#
# Manage the ticket email alert 
#
# what is the action to perform enable disable delete (and *_all) 
# force=1 tells it not to confirm actions it normally confirms.
#

ad_page_variables {alert_id what {return_url {/pvt/alerts.tcl}} {force 0}}

set db [ns_db gethandle] 
set user_id [ad_get_user_id]

set confirm_p 0

switch $what { 
    disable { 
        set sql "update ticket_email_alerts set active_p = 'f' where alert_id = $alert_id and user_id = $user_id" 
    } 
    disable_all { 
        set sql "update ticket_email_alerts set active_p = 'f' where user_id = $user_id" 
    } 
    enable { 
        set sql "update ticket_email_alerts set active_p = 't' where alert_id = $alert_id and user_id = $user_id" 
    }
    enable_all { 
        set sql "update ticket_email_alerts set active_p = 't' where user_id = $user_id" 
    }
    delete { 
        set sql "delete ticket_email_alerts where alert_id = $alert_id and user_id = $user_id"
    }
    delete_all { 
        set sql "delete ticket_email_alerts where user_id = $user_id"
        set confirm_p 1
    }
    default {
        ad_return_complaint 1 "<LI> I don't know how to $what the alert."
        return -code return
    }
}

if { $confirm_p && ! $force } { 
    set force 1
    ReturnHeaders 
    ns_write "[ad_header {Confirm delete all alerts}]
 <h1>Confirm delete all alerts</h1><form action=\"[ns_conn url]\">
 [export_ns_set_vars form force]
 [export_form_vars force]
 <blockquote>
 <input type=submit value=\"Yes\">
 </blockquote>
 </form>[ad_footer]"
    return 
}

if {[catch {ns_db dml $db $sql} errmsg]} { 
    ad_return_complaint 1 "<LI> I was unable to $what the alert.  Here was the message from the database: <pre>$errmsg</pre>"
    return

}

ad_returnredirect $return_url  

