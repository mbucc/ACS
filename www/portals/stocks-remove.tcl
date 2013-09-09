# /www/portals/stocks-remove.tcl

ad_page_contract {
    This will take in a user_id and a stock_symbol
    based off this information that stock_symbol will 
    be removed from the db

    @author spears@arsdigita.com 
    @creation-date May 2000
    @param symbol stock symbol to remove
    @param user_id
    @cvs-id stocks-remove.tcl,v 3.1.2.4 2000/07/21 04:03:23 ron Exp

} { 
	symbol:notnull
	user_id:naturalnum,notnull
}

set a_user_id [ad_verify_and_get_user_id]

if {$a_user_id != $user_id} {
	ad_return_complant 1 "<li> you must be logged in as a user to delete"
	return 
}


db_dml portal_stocks_remove "delete from portal_stocks where user_id = :user_id and symbol = :symbol" 

db_release_unused_handles

ad_returnredirect "stocks-personalize.tcl"







