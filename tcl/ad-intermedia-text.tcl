# $Id: ad-intermedia-text.tcl,v 3.0 2000/02/06 03:12:28 ron Exp $
# ad-intermedia-text.tcl
# 
# procs useful system-wide in conjunction with Oracle's Intermedia full-text
# indexer (an Oracle 8.1.5 feature)
#
# by philg@mit.edu July 25, 1999
#

proc_doc ad_intermedia_text_searching_hints {} {Returns an HTML fragment explaining to end-users how to use Intermedia's bizarro query language; this is basically annotation duct-tape on top of interMedia's fundamental flaws (it should really work like PLS or AltaVista or whatever)} {
    return {

By default, Oracle interMedia uses exact phrase matching.  Thus, the more
you type, the fewer hits you're likely to get.  Here are some ways that 
you can improve search relevance:

<dl>
<dt><b>about()</b>

<dd>This is Oracle's attempt to do concept queries, the way that
public Internet search engines do.  In theory, you'll get the most
relevant documents first.  In practice, we don't use this by default
because it seems to come up with too many wildly irrelevant hits.
Usage:  <code>about(how do I take a picture of a newborn)</code>
or <code>about(newborn photography)</code>

<dt><b>boolean operators</b>

<dd>You can do standard AND and OR queries using the words "and" and "or".
Usage: 
<ul>
<li><code>newborn and photography</code>
<li><code>newborn &amp; photography</code>
<li><code>newborn or photography</code>
<li><code>newborn and photography and not about(flash)</code>
</ul>

Note that <code>newborn photography</code> alone would be an exact
phrase search and wouldn't return documents unless these words
occurred right next to each other.

<dt><b>special characters</b>

<dd>Be careful with punctuation marks.  For example, the question mark
is the fuzzy matching character (<code>?photography</code> will find words
that are spelled similarly to "photography", useless if the body of text 
has many misspellings).  The exclamation point is the soundex character 
(<code>!Nikkon</code> should match "Nikon").

</dl>
    }
}



proc_doc ad_clean_query_for_intermedia {query_string} {Cleans up user input into a form suitable for feeding to interMedia. Tries to turn user input into a simple AND query.} {
    # Replace all ConText search operators with space. 
    regsub -all {[,&]+} $query_string { } query_string 

    # Replace all words that are ConText operators 
    regsub -all { (and|or) } $query_string { } query_string 

    # Separate all words with "&" to get an AND query. 
    return [join $query_string "&"] 
} 
