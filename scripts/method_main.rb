require 'net/https'
require 'rexml/document'
require 'riak'
# require 'mechanize'
# require 'selenium-webdriver'
require 'capybara/poltergeist'


def login_wars(target_url, name, password)
  Capybara.register_driver :polterge do |app|
    Capybara::Poltergeist::Driver.new(app, {:js_errors => true, :timeout => 5000})
  end

  session = Capybara::Session.new(:poltergeist)
  session.driver.headers = {
    'User-Agent' => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2564.97 Safari/537.36"
  }
  session.visit(target_url)
  input_name = session.find('input#name')
  input_password = session.find('input#password')
  input_name.native.send_key(name)
  input_password.native.send_key(password)

  submit = session.find('input.form_change', match: :first)
  submit.trigger('click')
  ########## check ##########
  # screenshot_file = 'login.png'
  # session.save_screenshot(screenshot_file)
  ###########################
  session
end

def get_history(history_url, history_last, name, session)
  url = "#{history_url}#{name}#{history_last}"
  session.visit(url)
  ########## check ##########
  # screenshot_file = 'history.png'
  # session.save_screenshot(screenshot_file)
  ###########################
  $log.info("get history html")
  session.html
end

def get_kif(kif_base_url, history)
  url = "#{kif_base_url}#{history}"
  $log.info("get url=>#{url}")
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  req = Net::HTTP::Get.new(uri.request_uri)
  res = http.request(req)

  battle_sorce = res.body
  wars_kif = battle_sorce[/receiveMove\((.+)\);/]
  wars_kif.delete('receiveMove(').delete(');').split('\t')
end

def parse_html(html)
  doc = Nokogiri::HTML.parse(html)
  analysis_list = []
  node_set = doc.css('.game_replay')
  node_set.each do |line|
    battle_data = line.at_css('a')[:onclick].gsub("appAnalysis(\'", '').gsub("\')", '')
    analysis_list << battle_data
  end
  analysis_list
end

def import_kifu(kifu, history, bucket)
  reg = /([\w\d]*)-([\w\d]*)-([\d]{8}_[\d]{6})/
  history.match(reg)
  $log.info("import key:[#{$3}]")
  # kif = bucket.get_or_new($3)
  kif = bucket.new($3)
  kif.data = {black: $1, white: $2, kifu: kifu}
  kif.store
end
