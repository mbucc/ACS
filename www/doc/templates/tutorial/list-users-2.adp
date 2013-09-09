<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id list-users-2.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
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
Sharing Data Sources
</h2>

part of a tutorial on the <a href="index.adp">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>

<p>Certain data sources are likely to be repeated across an entire
site or among a related group of templates.  In these situations it is
desirable to create and maintain the data source in one location.
Template data files can then reference these shared data sources,
where they are in central data libraries or in the data files of other
templates.  This lesson illustrates a simple example of referencing
the data source used to list all users from the sample data table.</p>

<h3>Create the specification file</h3>

<p>Create a file named <tt>users2.data</tt> in a test directory of
your server and enter the following specification:</p>

<%=[ad_util_get_source "samples/users2.data"]%> 

<p>Note that external data sources are referenced by specifying both
 <tt>src</tt> and <tt>name</tt> attributes.  The <tt>src</tt>
attribute must be the URL (relative or absolute) of a <em>data</em>
file, not a template.  You can thus reference data files associated
with templates, as well as standalone data files used as central
libraries of common data sources.</p>

<p>Also note that the data source processor makes absolute no
distinction between internal and external data sources.  External variables
may reference

<p><a href="samples/users.data">View the data dictionary</a></p>

<h3>Create the template</h3>

<p>Copy the template in <tt>samples/user.adp</tt> to users2.adp.</p>

<p><a href="samples/users2.adp">View results</a></p>

<a href="index">Tutorial Contents</a>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>













