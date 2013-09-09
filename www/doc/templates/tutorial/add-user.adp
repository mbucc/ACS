<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id add-user.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
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
Add a User
</h2>

part of a tutorial on the <a href="../index.adp">Dynamic Publishing
System</a> by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>

<p>This lesson introduces the form manager component of the publishing
system, which generates templated forms and handles validation and
database transactions for form submissions.  The objective of this
lesson is to create a simple form to add a user to the list of sample
users.  Subsequent lessons will expand on this example to illustrate
other features of the form manager.</p>

<h3>Create the form specification</h3>

<p>A form specification is a simple XML document that uses a standard
set of tags to describe a form and its individual elements.</p>

<p>Create a file named <tt>user-add.form</tt> in a test directory of
your server and enter the following specification:</p>

<%=[ad_util_get_source "samples/user-add.form"]%> 

<p>As this example shows, a form specification consists of some
general properties followed by any number of form elements.  In
particular pleas note:</p>

<ul>

<li>The <tt>dbaction</tt> element is set to insert.

<li>Each element maps to a column in the database table
<tt>ad_template_sample_users</tt>.  The column name is assumed to be
the same as the element name.  The <tt>datamap</tt> container also has
an optional <tt>column</tt> attribute that may be used with the name
of the form element and column are different.  The <tt>user_id</tt>
element is marked as a "parent" key, since it is the primary key for
the table.

<li>The hidden form element <tt>user_id</tt> has a default value that
is set based on a database query.

<li>All elements except for <tt>user_id</tt> use the default widget, which 
is a text input box.  They are also of the default data type, which is
text.

<li>The <tt>city</tt> and <tt>state</tt> elements are marked as optional.
They may be left blank by the user.  The other elements by default
are expected to be required.

<li>The <tt>state</tt> element has an additional <tt>attribute</tt>
attribute.  This may be used to add arbritary additional attributes
to the <tt>input</tt> or <tt>select</tt> tag, such as the <tt>maxlength</tt>
attribute or JavaScript event handlers, which may be used for
presubmission validation.

</ul>

<h3>Create the form template</h3>

<p>To embed the form into any page using a standard form template, you
can use the <tt>formtemplate</tt> tag to autogenerate the form
using a standard sitewide template:</p>

<%=[ad_util_get_source "samples/user-add.adp"]%> 

<a href="samples/user-add.adp">View the form</a>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>

