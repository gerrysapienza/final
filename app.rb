# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "geocoder"                                                                    #
require "bcrypt"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

events_table = DB.from(:events)
registrations_table = DB.from(:registrations)
users_table = DB.from(:users)

before do
    # SELECT * FROM users WHERE id = session[:user_id]
    @current_user = users_table.where(:id => session[:user_id]).to_a[0]
    puts @current_user.inspect
end

# Home page (all events)
get "/" do
    # before stuff runs
    @events = events_table.all
    view "events"
end

# Show a single event
get "/events/:id" do
    @users_table = users_table
    # SELECT * FROM events WHERE id=:id
    @event = events_table.where(:id => params["id"]).to_a[0]
    # SELECT * FROM registrations WHERE event_id=:id
    @registrations = registrations_table.where(:event_id => params["id"]).to_a
    # SELECT COUNT(*) FROM registrations WHERE event_id=:id AND going=1
    @count = registrations_table.where(:event_id => params["id"], :going => true).count
    view "event"
end

# Form to create a new Registration
get "/events/:id/registrations/new" do
    @event = events_table.where(:id => params["id"]).to_a[0]
    view "new_registration"
end

# Receiving end of new registration form
post "/events/:id/registrations/create" do
    registrations_table.insert(:event_id => params["id"],
                       :going => params["going"],
                       :user_id => @current_user[:id],
                       :comments => params["comments"])
    @event = events_table.where(:id => params["id"]).to_a[0]
    view "create_registration"
end

# Form to create a new user
get "/users/new" do
    view "new_user"
end

# Receiving end of new user form
post "/users/create" do
    puts params.inspect
    users_table.insert(:name => params["name"],
                       :email => params["email"],
                       :password => BCrypt::Password.create(params["password"]))
    view "create_user"
end

# Form to login
get "/logins/new" do
    view "new_login"
end

# Receiving end of login form
post "/logins/create" do
    puts params
    email_entered = params["email"]
    password_entered = params["password"]
    # SELECT * FROM users WHERE email = email_entered
    user = users_table.where(:email => email_entered).to_a[0]
    if user
        puts user.inspect
        # test the password against the one in the users table
        if BCrypt::Password.new(user[:password]) == password_entered
            session[:user_id] = user[:id]
            view "create_login"
        else
            view "create_login_failed"
        end
    else 
        view "create_login_failed"
    end
end

# Logout
get "/logout" do
    session[:user_id] = nil
    view "logout"
end

# Form to create a new ride
get "/event/new" do
    view "new_event"
end

# Receiving end of the create ride form
post "/event/create" do
    events_table.insert(:title => params["title"],
        :date => params["date"],
        :time => params["time"],
        :location => params["location"],
        :host_name => params["host_name"],
        :description => params["description"])
    @event = events_table.where(:id => params["id"]).to_a[0]
    view "create_event"
end