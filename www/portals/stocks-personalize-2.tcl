# /www/portals/stocks-personalize-2.tcl

ad_page_contract {    
    symbols, num_indices (optional) market_index<n>, 
    where num_indices is the number of 
    market indices we're allowing the user to choose 
    by checkbox on the previous page

    @author ?
    @creation-date ?
    @param symbol Stock symbol
    @cvs-id stocks-personalize-2.tcl,v 3.3.2.6 2000/09/22 01:39:01 kevin Exp

} {
    symbol
}    

set page_content "
 [ad_header "Verify Stock Symbol"]
 <h2> Verify Stock Symbol </h2>
 [ad_context_bar_ws_or_index / "ArsDigita"]
 <hr>
 <ul>
 <blockquote>
"

set user_id [ad_verify_and_get_user_id]

if {$symbol != ""} {
  append page_content "[verify_stock_symbol $symbol]"
} 


append page_content "
 </blockquote>
 </ul>
 [ad_footer]
"

doc_return  200 text/html $page_content












