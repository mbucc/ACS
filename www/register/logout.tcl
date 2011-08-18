# $Id: logout.tcl,v 3.2.2.1 2000/04/28 15:11:25 carsten Exp $
set db [ns_db gethandle]
ad_user_logout $db
ns_db releasehandle $db

ad_returnredirect "/"
#ad_returnredirect "/cookie-chain.tcl?cookie_name=[ns_urlencode ad_auth]&cookie_value=expired&expire_state=e&final_page=[ns_urlencode /]"
