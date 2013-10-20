# Register a new user.
# Created: Fri Oct 11 22:58:57 EDT 2013

def log(pass, name)
  puts ("%-70.70s" % name).gsub('  ', ' .') + (pass ? " PASS" : " FAIL")
end

require "watir-webdriver"
browser = Watir::Browser.new :ff
browser.goto "192.168.30.117:8000/pvt/home"

browser.text_field(:name => 'email').set 'a@b.com'
browser.text_field(:name => 'password').set 'abc'

f = browser.form(:name, "login")
f.submit

browser.text_field(:name => 'password_confirmation').set 'abc'
browser.text_field(:name => 'first_names').set 'fname'
browser.text_field(:name => 'last_name').set 'lname'
browser.text_field(:name => 'url').set 'http://www.google.com'

f1 = browser.form(:action, "user-new-2")
f1.submit

log(browser.text.include? "fname lname's workspace at Network",
    "Create user account")

browser.link(:text, "upload a portrait").click
log(browser.text.include? "Upload Portrait", "Display upload portrait form")

imgpath0="image.png"
imgpath1 = File.expand_path imgpath0




#puts browser.url
#puts browser.title

browser.close
