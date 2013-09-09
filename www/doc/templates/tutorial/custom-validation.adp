<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id custom-validation.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
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
Custom Validation
</h2>

part of a tutorial on the <a href="../index.adp">Dynamic Publishing
System</a> by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>

<p>The form manager validates submitted form values based on the data type
of the element in the form specification.  In some cases it is necessary
to perform more specialized validation before allowing processing to continue.
This lesson shows how to perform custom validation on a form element while
using the form manager.</p>

<h3>Create the form specification</h3>

<p>Copy the form specification created in the first form tutorial lesson 
(<tt>user-add.form</tt>) to <tt>user-add-state.form</tt>.

<p>Add a <tt>validate</tt> block to the <tt>state</tt> element like
so:</p>

<pre><%=[ns_quotehtml "
  <validate>
    <condition>
      expr \"! \[string match \[string toupper \$value] KS]\"
    </condition>
    <message>
      Sorry, residents of KS are not eligible to register.
    </message>
  </validate>"]%>
</pre>

<h3>Create the form template</h3>

<p>Copy the form template created in the first form tutorial lesson 
(<tt>user-add.adp</tt>) to <tt>user-add-state.adp</tt>.

<p>Try entering KS as the state of residence and submitting the form.</p>

<a href="samples/user-add.adp">View the form</a>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>

