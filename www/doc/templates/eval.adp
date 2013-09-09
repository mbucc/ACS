<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id eval.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
}
%>

<html>

<head>
<title>
Dynamic Publishing System
</title>
</head>

<body>

<h2>
Template Data Source Types: <tt>eval</tt>
</h2>

part of the <a href="index.adp">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>
<div align=right><a href="">Previous</a> | 
<a href="">Next</a>  | 
<a href="../spec.adp">Top</a></div>

<h3>Summary</h3>

<p>The <tt>eval</tt> data source encapsulates an arbitrary block of Tcl
code that returns values for the template.  The following general 
guidelines apply:</p>

<ul>

<li><p>There are no syntactic restrictions on the code.  Any well-written code
that works on a Tcl page should work within an eval data source as well.</p>

<li><p>One caveat to the previous statement: the less-than and
greater-than symbols must be escaped with a backslash to avoid
confusing the XML parser.</p>

<li><p>Eval code blocks are commonly misconceived as procedure bodies
that implicitly <tt>return</tt> a value on the last line.  In reality,
the <em>last</em> line of the code must be a procedure whose return
value corresponds with the <tt>structure</tt> attribute of the
datasource:</p>

<pre>
&lt;condition>
  set a "foo"
  set b "bar"
  $a$b  <-- Wrong!
&lt;/condition>

&lt;condition>
  set a "foo"
  set b "bar"
  format "$a$b" <-- OK (or set x "$a$b" would also work)
&lt;/condition>
</pre>

<p>Explicit <tt>return</tt> statements are <b>not</b> tolerated.  See the
notes below for examples.</p>

<li><p>The entire block of code is evaluated within a <tt>catch</tt>
statement.  When an error occurs, template processing is terminated
and the client is notified of a problem.</p>

<li><p>Database handles may be used in the code provided they are
released after use.</p>

<li><p>The code is evaluated in the global variable context.  As such, it
may refer to any variable set by previous datasources (both internal
and external) in the same file.  Beware of setting variables in your
code that may stomp on previously set data variables.</p>

</ul>

<h3><tt>onevalue</tt></h3>

<p>A <tt>onevalue</tt> eval should return a single value from the last
line of code in the block.  This value is then set as a global
variable by the template data processor.</p>

<pre><%=[ad_util_get_source "usage/eval_onevalue.data"]%></pre>

<h3><tt>onerow</tt></h3>

<p>A <tt>onerow</tt> eval should return a single ns_set from the last
line of code in the block.  Each key-value pair in the resulting ns_set
will then be set as a global variable by the template data processor.</p>

<pre><%=[ad_util_get_source "usage/eval_onerow.data"]%></pre>

<h3><tt>multirow</tt></h3>

<p>A <tt>multirow</tt> eval should return a list of ns_sets from the last
line of code in the block.  The entire list is then set as a global
variable for use by the <tt>multiple</tt> and <tt>grid</tt> tags.</p>

<pre><%=[ad_util_get_source "usage/eval_multirow.data"]%></pre>

<div align=right><a href="">Previous</a> | 
<a href="">Next</a>  | 
<a href="../spec.adp">Top</a></div>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>




