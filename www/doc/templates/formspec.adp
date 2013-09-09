<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id formspec.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
}
%>

<h1>Form Specification File</h1>

<hr>

<h3>Overview</h3>

<p>Like the template data specifications we have seen up to this
point, form specifications are also well-formed XML documents.  The
content of the two is completely different, however.  Rather than a
list of sources to derive dynamic data, the form specifications
describe the properties of each <em>element</em> in a form.  Basic
properties include:

<ul>
<li>the type of widget
<li>the type of data to be entered (i.e. text, number, email, url, etc.)
<li>default value(s) to initialize the widget
<li>a list of options to populate button groups and select lists
<li>mappings between the element value(s) and tables and columns in the
database
</ul>

<p>The form specification also contains general properties about the
form, including attributes of the <tt>form</tt> tag itself.</p>


<p>The form specification file is an XML document containing
sufficient information to generate a complete form.  The file has the
following generic structure:</p>

<pre>
&lt;form>

  <em>General 

<h3>General Properties</h3>

<p>The general properties apply to the form as a whole
rather than any particular element.  The <tt>name</tt>
property is used internally to define global variables
for each form element, and optionally by the template
author when referencing these variables.  The <tt>type</tt>
property is optional and may be used to specify that
the rendered form should be of type <tt>multipart</tt.  This
is required for forms containing file widgets and optional
otherwise. The <tt>dbaction</tt> property generally defines the type
of database actions to perform based on the form submission
(updates based on checkbox groups or select multiple widgets may
actually be performed by a delete-insert sequence).  A single
form may require several database statements to process, all of
which are contained in a single transaction.</p>

<p>The optional <tt>title</tt> and <tt>help</tt> properties may contain
a title and some explanatory text to place at the head of the form.</p>

<h3>Element Properties</h3>

<p>Each form specification contains an <tt>elements</tt>
container, within which is a series of one or more
elements in the order in which they should appear in an
automatically generated form.</p>

<p>Each element possesses a <tt>name</tt> property, which the
template author uses to identify the element and which is
used to name the element in the rendered form.</p>

<p>The <tt>label</tt> and <tt>help</tt> properties contain
text that may be referenced by template authors when laying
out the form template.</p>

<p>The <tt>widget</tt> property specifies the type of widget
to generate for the element.  Any of the standard form elements
may be used, in addition to custom widgets composed of
combinations of form elements (i.e., the date widget included
with the form manager).  The <tt>width</tt> attribute is used
to set the <tt>SIZE</tt> attribute of the <tt>INPUT</tt> tag,
as well as the <tt>COLS</tt> attribute of the <tt>TEXTAREA</tt>
tag.  The <tt>height</tt> attribute is used to the <tt>SIZE</tt>
attribute of the <tt>SELECT</tt> tag, as well as the <tt>ROWS</tt>
attribute of the <tt>TEXTAREA</tt> tag.</p>

<p>The <tt>options</tt> property provides a flexible way to
specify the labels and values for radio and checkbox groups and
select lists.  If the <tt>static</tt> method is specified, then a
list of items is expected in the following form:</p>

<pre>
&lt;options method="static">
  &lt;item value="value1">label 1&lt;/item>
  &lt;item value="value2">label 2&lt;/item>
  &lt;item value="value2">label 3&lt;/item>
  ...
&lt;/options>
</pre>

<p>If the <tt>query</tt> method is specified, then a database query
is expected in the following form (note that the query must rename the first column
<tt>label</tt> and the second <tt>value</tt>):</p>

<pre>
&lt;options method="query">
  select
    col1 as label, col2 as value
  from
    table
  ...
&lt;/options>
</pre>

<p>If the <tt>eval</tt> method is specified, then Tcl code
is expected which should result in a list of duplets in the form

<pre>{ {label1 value1} {label2 value2} ... }</pre>

<p>The <tt>default</tt> property specifies the default values to set
the form element when no other values are currently known (i.e., for a
"new" or "add" type of form, as opposed to an "update" form in which
the user has previously given a value).  The methods are the same as
for the <tt>options</tt> property, although the format expected for
each is different.  Static defaults should be a single vertical-bar
delimited string (i.e., <tt>value1|value2|value3</tt>).  The query
method for this property should specify a single column query, and the
eval method should specify code that returns a simple list.</p>

<p>The final section of the element block is zero or more
<tt>dbmap</tt> properties, which specify how and where the values
obtained from a form element map into the database.  The <tt>key</tt>
attribute is critical for proper handling of the form submission
(although it may become optional in a future release since the
form manager can actually query for this information from the database
data dictionary tables).
The <tt>column</tt>
property is optional and needs to be used only when the column name
in the database differs from the name of the form element.</p>

<h3>Pre- and post-processing</h3>

<p>It is frequently the case that a form submission handler must do
more than just modify some database tables.  Sending mail and setting
cookies are examples of other common actions.  The form specification file
may include <tt>preprocess</tt> and <tt>postprocess</tt> blocks that
encapsulate such actions within a structured framework.</p>