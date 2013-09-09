# /www/bannerideas/index.tcl
ad_page_contract {
    Main page for banner ideas.  Presents them.
    
    @author xxx
    @date unknown
    @cvs-id index.tcl,v 3.1.2.3 2000/09/22 01:36:40 kevin Exp
} {

}

set page_content "[ad_header "Banner Ideas"]

<h2>Banner Ideas</h2>

[ad_context_bar_ws_or_index "All Banner Ideas"]

<hr>
"

db_foreach banner_idea_list_query "select idea_id, intro, more_url, picture_html
from bannerideas" {
    append page_content [bannerideas_present $idea_id $intro $more_url $picture_html]
}

append page_content "

[ad_footer]
"


doc_return  200 text/html $page_content
