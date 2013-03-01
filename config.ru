
require 'rubygems'

require './server'
set :environment, :production

run Sinatra::Application

