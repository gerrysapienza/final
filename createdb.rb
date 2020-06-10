# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :events do
  primary_key :id
  String :title
  String :description, text: true
  String :date
  String :time
  String :location
  String :host_name
end
DB.create_table! :registrations do
  primary_key :id
  foreign_key :event_id
  foreign_key :user_id
  Boolean :going
  String :name
  String :email
  String :comments, text: true
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
end

# Insert initial (seed) data
events_table = DB.from(:events)

events_table.insert(title: "Harmon Hundred", 
                    description: "CCCC's annual signature riding event",
                    date: "2020-08-30",
                    time: "8:00 AM",
                    location: "Wilmot Union High School",
                    host_name: "Paul")

events_table.insert(title: "Honey Do Avoiders", 
                    description: "Usually a large number of riders show up. Groups of 5+ for every pace level are normal. Distances range from 35-60 Miles.",
                    date: "2020-06-13",
                    time: "8:00 AM",
                    location: "Paul Douglas Forest Preserve",
                    host_name: "Emily")
