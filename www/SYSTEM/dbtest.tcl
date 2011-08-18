# $Id: dbtest.tcl,v 3.1 2000/02/29 04:39:43 jsc Exp $
# this is called by server monitoring scripts, such as 
# keepalive (see http://arsdigita.com/free-tools/keepalive.html)
# if it doesn't return "success" then they are supposed
# to kill the AOLserver

# you can also use this with our Uptime monitoring system,
# described in Chapter 15 of http://photo.net/wtr/thebook/

# this tests total db connectivity

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select sysdate from dual"]

if { $selection == "" } {
     ns_return 500 text/plain "failed"	
} else {
     ns_return 200 text/plain "success"
}


