# Register a new user.
# Created: Fri Oct 11 22:58:57 EDT 2013

require "watir-webdriver"
browser = Watir::Browser.new :ff
browser.goto "192.168.30.117:8000/pvt/home"

browser.text_field(:name => 'email').set 'a0@t.com'
browser.text_field(:name => 'password').set 'abc'
f = browser.form(:name, "login")
f.submit

browser.text_field(:name => 'password_confirmation').set 'abc'
browser.text_field(:name => 'first_names').set 'fname'
browser.text_field(:name => 'last_name').set 'lname'

f1 = browser.form(:action, "user-new-2")
f1.submit

# browser.text.include? 'fname lname's workspace at Network'

puts browser.url
puts browser.title

browser.close
