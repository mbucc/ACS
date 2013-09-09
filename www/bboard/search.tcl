# /www/bboard/search.tcl
ad_page_contract {
    Searches the bboards for query_string

    @param query_string the string being searched on
    @param topic the name of the bboard topic
    @param topic_id the ID of the bboard topic

    @cvs-id search.tcl,v 3.1.2.3 2000/09/22 01:36:55 kevin Exp
} {
    query_string
    topic
    topic_id
}

# -----------------------------------------------------------------------------

doc_return  200 text/html "

<HTML><BASE F0NTSIZE=3>

<HEAD>

<TITLE>$topic Search Results</TITLE>

</HEAD>

<FRAMESET ROWS=\"25%,*\">

<FRAME SCROLLING=\"yes\" NAME=\"subject\" SRC=\"search-subject.tcl?[export_url_vars topic topic_id]&query_string=[ns_urlencode $query_string]\">

<FRAME SCROLLING=\"yes\" NAME=\"main\" SRC=\"search-default-main.tcl?[export_url_vars topic topic_id]&query_string=[ns_urlencode $query_string]\">

</FRAMESET>
<NOFRAME>

<BODY BGCOLOR=\"#FFFFFF\" TEXT=\"#000000\">

This bulletin board system can only be used with a frames-compatible
browser.

<p>

Perhaps you should consider running Netscape 2.0 or later?

</BODY></HTML>

</NOFRAME>

</FRAMESET>

"