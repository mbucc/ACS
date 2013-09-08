# www/portals/stocks-add.tcl

ad_page_contract {
    
    symbols, num_indices (optional) market_index<n>, where num_indices
    is the number of market indices we're allowing the user to choose by
    checkbox on the previous page
    
    @author cspears@arsdigita.com
    @param symbol Stock symbol
    @creation-date May 18, 2000
    @cvs-id stocks-add.tcl,v 3.1.2.5 2000/07/21 04:03:21 ron Exp

} {
    symbol:notnull
}

set user_id [ad_verify_and_get_user_id]

db_dml portal_stock_add "insert into portal_stocks (symbol, user_id) values (:symbol, :user_id)" 

db_release_unused_handles

ad_returnredirect /portals/user$user_id-1.ptl


