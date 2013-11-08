# test_utils.rb
# Created: Wed Nov  6 19:45:30 EST 2013
# Ruby functions that seem resusable for tests.


load "octo_ipsum.rb"

$HOST = "192.168.30.117:8000"


def user(email, password, firstname = "", lastname = "", url = "")
	return {
		:email => email,
		:password => password,
		:first => firstname,
		:last => lastname,
		:url => url,
	}
end

$admin_user = user("system", "changeme")

def news(title, paragraphs_n = 5)
	return {
		:title => title,
		:body => octo_ipsum(paragraphs_n)
	}
end

def comment(paragraphs_n = 1)
	return {
		:body => octo_ipsum(paragraphs_n)
	}
end

# log(true, "My Test", 40)
#       --> "My Test . . . . . . . . . . . . . . PASS"
def log(pass, name, width = 78)
	n = width - 5
	fmt = "%%-%d.%ds" % [n,n]
	return (fmt % name).gsub("  ", " .") + (pass ? " PASS" : " FAIL")
end

# Raise error if target string is not found on current page.
def assert(browser, target, fcn)
	if ! browser.text.include? target then
		raise fcn + ": " + target + " not found."
	end
end

# Create a new community user with the given identity.
def add_user(browser, user)

	browser.goto $HOST + "/pvt/home"

	submit_login_form(browser, user)

	browser.text_field(:name => 'password_confirmation').set user[:password]
	browser.text_field(:name => 'first_names').set user[:first]
	browser.text_field(:name => 'last_name').set user[:last]
	if user[:url][0] then
		browser.text_field(:name => 'url').set user[:url]
	end

	f1 = browser.form(:action, "user-new-2")
	f1.submit

	fcn = "add_user(%s, %s)" % [browser, user]
	target = "%s %s's workspace at " % [user[:first], user[:last]]
	assert(browser, target, fcn)
end

# Logout a currently logged in user.
def logout(browser)
	browser.goto $HOST + "/register/logout"
	fcn = "logout(%s)" % browser
	assert(browser, "Login", fcn)
end

def submit_login_form(browser, user)
	browser.text_field(:name => 'email'   ).set user[:email]
	browser.text_field(:name => 'password').set user[:password]
	begin
		f = browser.form(:name, "login")
		f.submit
	rescue 
		browser.button(:text, "Submit").click
	end
end

def wait_then_click(browser, link_text)
	timeout_in_seconds = 5
	begin
		Watir::Wait.until(timeout_in_seconds) { browser.text.include? link_text }
		browser.link(:text, link_text).click
	rescue Exception => e
		raise "wait_then_click(%s, '%s'): %s" % [browser, link_text, e]
	end
end

# Submit a news item from the given user and approve it.
def add_news(browser, user, news)

	browser.goto $HOST + "/news"

	browser.link(:text, "suggest an item").click

	submit_login_form(browser, user)

	# Submit the story.
	browser.text_field(:name => 'title').set news[:title]
	browser.text_field(:name => 'body').set news[:body]
	f1 = browser.form(:action, "post-new-2")
	f1.submit

	# Confirm the submission.
	f1 = browser.form(:action, "post-new-3")
	f1.submit

	# Logout of user that submitted story.
	logout(browser)

	# Have admin approve the story.
	submit_login_form(browser, $admin_user)
	wait_then_click(browser, "Site-Wide Administration")
	wait_then_click(browser, "all")
	wait_then_click(browser, news[:title])
	wait_then_click(browser, "Approve")
	logout(browser)
end

# Add a comment to a news story.
def add_comment(browser, user, news, comment)

	browser.goto $HOST + "/news"

	browser.link(:text, news[:title]).click
	wait_then_click(browser, "Add a comment")
	login(browser, user)


	submit_login_form(browser, user)

	# Submit the story.
	browser.text_field(:name => 'title').set news[:title]
	browser.text_field(:name => 'body').set news[:body]
	f1 = browser.form(:action, "post-new-2")
	f1.submit

	# Confirm the submission.
	f1 = browser.form(:action, "post-new-3")
	f1.submit

	# Logout of user that submitted story.
	logout(browser)

	# Have admin approve the story.
	submit_login_form(browser, $admin_user)
	wait_then_click(browser, "Site-Wide Administration")
	wait_then_click(browser, "all")
	wait_then_click(browser, news[:title])
	wait_then_click(browser, "Approve")
	logout(browser)
end
