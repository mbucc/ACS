# $Id: enter-basket-email-final.tcl,v 3.0 2000/02/06 03:42:58 ron Exp $
set_form_variables
set_form_variables_string_trim_DoubleAposQQ

# ad_id, email

set insert_sql "insert into user_picks (email, ad_id) 
                values ('$QQemail',$QQad_id)"

set db [gc_db_gethandle]

ns_db dml $db $insert_sql

ns_write "HTTP/1.0 302 Found
Location: basket-home.tcl
MIME-Version: 1.0
Set-Cookie:  HearstClassifiedBasketEmail=$email; path=/;
"
