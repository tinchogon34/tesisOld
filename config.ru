require 'rubygems'
require 'bundler'

Bundler.require

require './server'
set :environment, :production
run Sinatra::Application

