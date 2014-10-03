#!/usr/bin/env ruby

Dir[File.expand_path("../../vendor/bundle/ruby/2.1.0/gems/*", __FILE__)].each do |dir|
  $:.unshift "#{dir}/lib"
end

require 'rubygems'
require 'mechanize'

log = File.open(File.expand_path("../../../../../log/#{Time.now.strftime '%Y%m%d'}.log", __FILE__), "a")
# log = File.open("/Users/hasumi/work/vote_shimanekko/log/#{Time.now.strftime '%Y%m%d'}.log", "a")
log.puts 'スクリプト開始'

begin
  accounts = []
  File.open(File.expand_path('../../../../../configs', __FILE__), "r") do |io|
    io.each do |line|
      next unless line.match(/.+@.+:.+/)
      tmp = line.split(":", 3)

      agent = Mechanize.new
      agent.user_agent = tmp[2].strip
      agent.redirect_ok = true
      agent.follow_meta_refresh = true

      accounts.push({email: tmp[0].strip, password: tmp[1].strip, agent: agent})
    end
    accounts.shuffle!
  end

  accounts.each do |account|
    start_page = account[:agent].get('http://www.yurugp.jp/vote/detail.php?id=00000021')
    vote_page = account[:agent].submit(start_page.forms[0])
    vote_form = vote_page.forms[0]
    vote_form.send("data[Member][email]", account[:email])
    vote_form.send("data[Member][password]", account[:password])
    log.puts "アカウント：#{account[:email]} で投票します"
    log.puts"ユーザーエージェントは#{account[:agent].user_agent}です"
    result = account[:agent].submit(vote_form)
    if result.parser.css('.section').text.include? '投票完了'
      log.puts '=> 投票完了'
    elsif result.parser.css('.section').text.include? '本日は既に投票済みです'
      log.puts '=> 本日は既に投票済みです'
    else
      log.puts '=> 不明なエラーです'
      log.puts result.parser.css('.section').text
    end
    result.link_with(text: 'ログアウトする').click
    sleep 0.1
  end
rescue => e
  log.puts e.to_s
  log.puts 'スクリプト異常終了'
  log.close
end

log.puts 'スクリプト正常終了'
log.close