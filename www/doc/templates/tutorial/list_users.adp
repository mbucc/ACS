<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id list_users.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
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
Repetitive Dynamic Content
</h2>

part of a tutorial on the <a href="index.adp">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>

<p>This lesson illustrates how to deal with repetitive dynamic content.
</p>

<h3>Create the specification file</h3>

<p>Create a file named <tt>users.data</tt> in a test directory of
your server and enter the following specification:</p>

<%=[ad_util_get_source "samples/users.data"]%> 

<p>
</p>

<p><a href="samples/users.data">View the data dictionary</a></p>

<h3>Create the template</h3>

<p>Note that the template uses the <tt>multiple</tt> tag to specify the
formatting for each row returned by the <tt>users</tt>
query:</p>

<%=[ad_util_get_source "samples/users.adp"]%> 

<p>The banding effect is accomplished with <tt>if</tt> statements
using the <tt>rownum</tt> variable, which is set implicitly for
each row processed by the <tt>multiple</tt> tag.</p>

<p><a href="samples/users.adp">View results</a></p>

<a href="index">Tutorial Contents</a>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>













