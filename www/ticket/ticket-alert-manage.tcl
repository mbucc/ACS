# /www/ticket/ticket-alert-manage.tcl
ad_page_contract {
    Manage the ticket email alert 
    
    @param alert_id the alert to modify
    @param what which action to perform.  One of <code>enable</code>,
           <code>enable_all</code>, <code>disable</code>, 
           <code>disable_all</code>, <code>delete</code>
           or <code>delete_all</code>
    @param return_url where to go when we are done
    @param force whether or not to confirm actions

    @author original author unknown
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @cvs-id ticket-alert-manage.tcl,v 3.1.6.5 2000/09/22 01:39:24 kevin Exp
} {
    alert_id:integer,notnull
    what 
    {return_url "/pvt/alerts.tcl"} 
    {force 0}
}

# -----------------------------------------------------------------------------
 
set user_id [ad_verify_and_get_user_id]

set confirm_p 0

switch $what { 
    disable { 
        set sql "update ticket_email_alerts set active_p = 'f' where alert_id = :alert_id and user_id = :user_id" 
    } 
    disable_all { 
        set sql "update ticket_email_alerts set active_p = 'f' where user_id = :user_id" 
    } 
    enable { 
        set sql "update ticket_email_alerts set active_p = 't' where alert_id = :alert_id and user_id = :user_id" 
    }
    enable_all { 
        set sql "update ticket_email_alerts set active_p = 't' where user_id = :user_id" 
    }
    delete { 
        set sql "delete ticket_email_alerts where alert_id = :alert_id and user_id = :user_id"
    }
    delete_all { 
        set sql "delete ticket_email_alerts where user_id = :user_id"
        set confirm_p 1
    }
    default {
        ad_return_complaint 1 "<LI> I don't know how to $what the alert."
        return -code return
    }
}

if { $confirm_p && ! $force } { 
    set force 1

    doc_return  200 text/html "
[ad_header {Confirm delete all alerts}]
 <h2>Confirm delete all alerts</h2>

<form action=\"[ns_conn url]\">
 [export_ns_set_vars form force]
 [export_form_vars force]
 <blockquote>
 <input type=submit value=\"Yes\">
 </blockquote>
 </form>
[ad_footer]"

    return 
}

if {[catch {db_dml alert_modify $sql} errmsg]} { 
    ad_return_complaint 1 "<LI> I was unable to $what the alert.  Here was the message from the database: <pre>$errmsg</pre>"
    return
}

ad_returnredirect $return_url  

