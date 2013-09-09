<% 
  global errorSet
  set redirect_url [ns_set get $errorSet redirect_url]
  ns_returnredirect "/register/signin.adp?redirect_url=$redirect_url" 
%>