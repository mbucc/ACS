<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id contest.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
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
Code Evaluation
</h2>

part of a tutorial on the <a href="index.adp">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>

<p>This lesson illustrates how the template specification can
provide a structured framework for procedural code that generates
dynamic data for a page.
</p>

<h3>Create the specification file</h3>

<p>Create a file named <tt>contest.data</tt> in a test directory of
your server and enter the following specification:</p>

<%=[ad_util_get_source "samples/contest.data"]%> 

<p>
In this case, the first data source creates a list of <tt>ns_set</tt> data
structures to hold the contestant data.  The code specified by the
second data source uses this data to pick a contest winner.
</p>

<p>Note that any type of Tcl code may be executed by a data source,
provided that the last command in the code returns the data structure
stipulated by the data source's <tt>structure</tt> property.  Data
sources are processed in the order in which they are listed in the
specification file, so the code for a data source may safely refer to
variables created by other data sources that are higher in the file.
</p>

<p>The inclusion of arbitrary amounts of Tcl code in the 
specification file itself should be only be done after considering
the implications.  For complex pages it is clearly convenient to have
procedural and declarative data mixed in a single file.  However,
if a particular data source requires more than a few lines of code
to create, then you should consider the possibly that at least some
of the code will be useful elsewhere as well, and thus is better
suited to encapsulation in a proc that resides in the Tcl private library.</p>

<p>The encapsulation of as much code as possible in procs is also
desirable from a performance standpoint.  Code in an <tt>eval</tt>
data source must be evaulated every time a page is requested,
as opposed to a proc which must only be parsed once and then is
held resident in shared memory.</p>

<p><a href="samples/contest.data">View the data dictionary</a></p>

<h3>Create the template</h3>

<p>The template for this lesson does not introduce anything new:</p>

<%=[ad_util_get_source "samples/contest.adp"]%> 

<p><a href="samples/contest.adp">View results</a></p>

<a href="index">Tutorial Contents</a>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>













