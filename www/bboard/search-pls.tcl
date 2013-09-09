# /www/bboard/search-pls.tcl
ad_page_contract {
    Page to search the bboards using PLS

    @param query_string the string to search on
    @param topic the topic to search in

    @cvs-id search-pls.tcl,v 3.1.2.3 2000/09/22 01:36:54 kevin Exp
} {
    query_string
    topic
}

# -----------------------------------------------------------------------------

doc_return  200 text/html "

<HTML><BASE F0NTSIZE=3>

<HEAD>

<TITLE>$topic Search Results</TITLE>

</HEAD>

<FRAMESET ROWS=\"25%,*\">

<FRAME SCROLLING=\"yes\" NAME=\"subject\" SRC=\"search-pls-subject.tcl?[export_url_vars topic topic_id]&query_string=[ns_urlencode $query_string]\">

<FRAME SCROLLING=\"yes\" NAME=\"main\" SRC=\"search-pls-default-main.tcl?[export_url_vars topic topic_id]&query_string=[ns_urlencode $query_string]\">

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

