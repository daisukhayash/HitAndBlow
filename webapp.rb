# -*- encoding: utf-8 -*-

require 'rubygems'
require 'sinatra'
require 'json'
require 'haml'
require 'sass'
$LOAD_PATH.unshift(File.join File.dirname(__FILE__), 'lib')
require 'hitandblow/solver'

set :haml, :format => :html5
set :hab, HitAndBlow::Solver.new 100.0, 25.0

before do
  @title = 'Hit & Blow'
end

before '/*.json' do
  content_type 'application/json'
end

get '/' do
  haml :index
end

get '/*.css' do |path|
  scss path.to_sym
end

get '/expect.json' do
  @mes = {
    :answer => settings.hab.expect
  }.to_json
end

post '/post' do
  answer = params[:answer]
  hit = params[:hit]
  blow = params[:blow]
  
  settings.hab.feedback answer, hit.to_i, blow.to_i

  @mes = {
    :answer => answer,
    :hit => hit,
    :blow => blow
  }.to_json
end