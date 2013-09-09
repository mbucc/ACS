<%
ad_page_contract {

	@author ?
	@creation-date ?
	@cvs-id adp-parser.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp

}
%>

<h1>Superfancy ADP Parser</h1>

<hr>

<p>The existing fancy adp parser does not permit nesting of 
registered tags.  This is a sorely lacking feature from the
standpoint of the templating system.</p>

<p>The <a href="http://aolserver.lcs.mit.edu/sdm/package-repository.tcl?current_entry=FILE%20%2fAOLserver%2fas3b5%2fnsd%20adpfancy%2ec&package_id=1">fancy adp parser code</a> currently searches for the end tag by a blind
linear search starting from the character following the open tag:</p>

<pre>
    /*
     * If it requires an endtag then ensure that there
     * is one. If not, warn and spew text.
     */
  	    
    if (rtPtr->endtag &&
	((end = Ns_StrNStr(top, rtPtr->endtag)) == NULL)) {
  
</pre>

<p>To find the correct end tag for a registered open tag, we need to
replace the call to Ns_StrNStr with a call to something like this:</p>

<pre>

static char * 
BalancedEndTag(char *in, RegTag *rtPtr)
{

  int tag_depth = 1;
  int taglen, endlen;

  taglen = strlen(rtPtr->tag);
  endlen = strlen(rtPtr->endtag);

  while (tag_depth) {

    /*  
     * Scan ahead for a '<'
     */

    while (*in != '<') {
      ++in;
      if (*in == '\0') return NULL;
    }

    ++in;

    /*
     * The current parser seems to allow white space between < and the tag
     */

    while (isspace(UCHAR(*in))) {
        ++in;
    }

    /*  
     * If the next word matches the close tag, then decrement tag_depth
     */

    if (strncasecmp(in, rtPtr->endtag, endlen) {
      tag_depth--;
    }

    /*  
     * else if the next word matches the open tag, then increment tag_depth
     */

    else if (strncasecmp(in, rtPtr->tag, taglen) {
      tag_depth++;
    }
  }

  return in;
}

</pre>


