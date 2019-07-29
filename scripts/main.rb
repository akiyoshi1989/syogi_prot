require 'logger'
require 'yaml'
$LOAD_PATH.push(__dir__)

require 'method_main'

config = ARGV[0]
configure    = YAML.load_file(config)
spool        = configure['spool_dir']
log_conf     = configure['log']
log_file     = log_conf['log_file']
log_period   = log_conf['log_period']
url_conf     = configure['url']
target_url   = url_conf['target_url']
login_page   = url_conf['login_page']
history_page = url_conf['history_page']
history_last = url_conf['history_last']
kif_base_url = url_conf['kif_base_url']
user_conf    = configure['user']
name         = user_conf['name']
password     = user_conf['password']
riak_conf    = configure['riak']
bucket_type  = riak_conf['bucket_type']
bucket       = riak_conf['bucket']

$log = Logger.new(log_file, log_period)
$log.datetime_format = '%Y-%m-%d %H:%M:%S'

WRITE_MODE = 'w'
READ_MODE = 'r'

begin
  $log.info('============= START =============')
  start_time = Time.now
  session = login_wars(login_page, name, password)

  history_data = get_history(history_page, history_last, name, session)
  history_list = parse_html(history_data)
  $log.info("history list number : #{history_list.size}")
  client = Riak::Client.new(:nodes => [{:host => "127.0.0.1", :protocol => "pbc", :pb_port => 8087}])
  # client = Riak::Client.new(:nodes => [{:host => "loalhost", :protocol => "pbc", :pb_port => 8087}])
  bucket = client.bucket_type(bucket_type).bucket(bucket)
  history_list.each do |history|
    wars_kif = get_kif(kif_base_url, history)
    import_kifu(wars_kif, history, bucket)
  end
rescue => e
  $log.error(e)
end
$log.info("process speed : #{(Time.now - start_time).round(2)}sec")
$log.info('=============  END  =============')
