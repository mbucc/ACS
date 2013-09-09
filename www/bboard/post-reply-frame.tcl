# /www/bboard/post-reply-frame.tcl
ad_page_contract {
    @param refers_to the message this reply is to

    @cvs-id post-reply-frame.tcl,v 3.1.2.3 2000/09/22 01:36:52 kevin Exp
} {
    refers_to
}

# -----------------------------------------------------------------------------

doc_return  200 text/html "

<HTML><BASE F0NTSIZE=3>

<HEAD>

<TITLE>Bulletin Board System</TITLE>

</HEAD>

<FRAMESET ROWS=\"25%,*\">

<FRAME SCROLLING=\"yes\" NAME=\"subject\" SRC=\"post-reply-top.tcl?refers_to=$refers_to\">

<FRAME SCROLLING=\"yes\" NAME=\"main\" SRC=\"post-reply-form.tcl?refers_to=$refers_to\">

</FRAMESET>

<NOFRAME>

<BODY BGCOLOR=\"#FFFFFF\" TEXT=\"#000000\">

This bulletin board system can only be used with a frames-compatible
browser.

<p>

Perhaps you should consider running Netscape 2.0?

</BODY></HTML>

</NOFRAME>

</FRAMESET>

"
