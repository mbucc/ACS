# Upload a portrait.
# Created: Sun Oct 20 10:54:21 EDT 2013

require "watir-webdriver"
require "pry"

browser = Watir::Browser.new :ff
browser.goto "192.168.30.117:8000"

# Login
browser.text_field(:name => 'email').set 'system'
browser.text_field(:name => 'password').set 'changeme'
f = browser.form(:action, "register/user-login")
f.submit

# Go to upload portrait screen
browser.link(:text, "upload a portrait").click

# Enter IRB for debugging.
#binding.pry

file = browser.file_field(:name, "upload_file")
file.send_keys("/tmp/abc.txt")
upload = browser.button(:value, "Upload")
upload.click

#browser.close
