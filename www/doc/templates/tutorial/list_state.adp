<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id list_state.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
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
Conditional Statements
</h2>

part of a tutorial on the <a href="index.adp">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>

<p>The previous lesson illustrated how to deal with repetitive dynamic 
content.  In cases where a list may have zero items, the
template writer may want to display a special message to that effect.
The template system provides a mechanism for dealing with such
situations, where the appearance of the template must vary
to suit the data.
</p>

<h3>Create the specification file</h3>

<p>Create a file named <tt>state.data</tt> in a test directory of
your server and enter the following specification:</p>

<%=[ad_util_get_source "samples/state.data"]%> 

<p>
</p>

<p><a href="samples/state.data">View the data dictionary</a></p>

<h3>Create the template</h3>

<p>The template for this lesson illustrates a simple use of the
<tt>if</tt> tag.  

<%=[ad_util_get_source "samples/state.adp"]%> 

The template tailors the output by checking
 the <tt>rowcount</tt>
variable associated the <tt>users</tt> data source.  This is
a special variable that is always set when a query is
performed.</p>

<p>There are alternate forms for the <tt>if</tt> tag parameters.
The first form relies on a simple conditional syntax that
is intended for general use by template authors.  
Global variables are referenced by enclosing their names in
percent signs.  Operators include <tt>eq</tt>, <tt>ne</tt>,
<tt>gt</tt>, <tt>lt</tt>, <tt>ge</tt>, and <tt>le</tt>.</p>

<p>When a simple expression will not suffice, the second
form accepts arbitrary Tcl code that is evaluated as as
a conditional expression.  For example:</p>

<pre>
&lt;if eval="${lesson4.users.rowcount} == 0"&gt;
</pre>

<p>would produce equivalent results to the first <tt>if</tt> tag
in the template listing above.</p>

<p><a href="samples/state.adp?state=CA">View results (state = CA)</a></p>
<p><a href="samples/state.adp?state=RI">View results (state = RI)</a></p>

<a href="index">Tutorial Contents</a>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>













