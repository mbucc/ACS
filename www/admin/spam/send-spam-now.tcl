# $Id: send-spam-now.tcl,v 3.0 2000/02/06 03:30:09 ron Exp $

ReturnHeaders
ns_write "running spam queue"
send_scheduled_spam_messages 
ns_write "<p>done"
