<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id first_name.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
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
Linking Data Sources
</h2>

part of a tutorial on the <a href="index.adp">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>

<p>This lesson illustrates how to use a sequence of dependent data sources 
to prepare dynamic content for a template.
</p>

<h3>Create the specification file</h3>

<p>Create a file named <tt>name.data</tt> in a test directory of
your server and enter the following specification:</p>

<%=[ad_util_get_source "samples/name.data"]%> 

<p>This specification contains two data sources.  The first data
source is a CGI parameter that must be included in the URL.  If
it is not found or null, the filter will return a standard
error message to the user.</p>

<p>The data sources are evaluated in the order in which they appear in
the file, so the value from the first data source can be referenced in
the second.  Note that the variable must be enclosed in curly braces
because it contains a period.</p>

<p><a href="samples/name.data">View the data dictionary</a></p>

<h3>Create the template</h3>

<p>The template for this lesson does not introduce anything new:</p>

<%=[ad_util_get_source "samples/name.adp"]%> 

<p><a href="samples/name.adp?user_id=81">View results</a></p>

<a href="index">Tutorial Contents</a>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>













