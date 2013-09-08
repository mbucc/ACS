<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id test.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
}
%>

<p>Say you have a registered tag <tt>hello</tt>, handled by
this proc:</p>

<pre>
ns_register_adptag hello helloproc

proc helloproc { tags } {

  return [ns_set value $tags 0]
}
</pre>

<p>If your template contains:</p>

<pre>&lt;hello fred="%julia%"></pre>

<p>the result is:</p>

<pre><var fred="%julia%"></pre>

<p>If your template contains:</p>

<pre>&lt;hello fred="julia % victoria"></pre>

<p>the result is:</p>

<pre><var fred="julia % victoria"></pre>

<p>So basically anything with a % in it is bungled.</p>

<p>A more serious problem occurs with valueless attributes.
If your template contains:</p>

<pre>&lt;hello fred></pre>

<p>the server crashes entirely!</p>

<p>Both these situations were handled correctly in AOLserver 2.3.3.</p>

