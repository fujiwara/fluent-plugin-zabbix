require 'helper'

if ENV['LIVE_TEST']
  require "glint"
  require "tmpdir"
  system "sh -c 'cd mockserver && go build mockserver.go'"
end

class ZabbixOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
    if ENV['LIVE_TEST']
      $dir = Dir.mktmpdir
      $server = Glint::Server.new(10051, { :timeout => 3 }) do |port|
        exec "./mockserver/mockserver", $dir.to_s + "/trapper.log"
      end
      $server.start
    end
  end

  CONFIG = %[
    zabbix_server  127.0.0.1
    host           test_host
    add_key_prefix ${tag}
    name_keys      foo, bar, baz, f1, f2
  ]

  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::ZabbixOutput, tag).configure(conf)
  end

  def test_write
    d = create_driver
    now = Time.now.to_i
    if ENV['LIVE_TEST']
      d.emit({"foo" => "test value of foo"}, now)
      d.emit({"bar" => "test value of bar"}, now)
      d.emit({"baz" => 123.4567 }, now)
      d.emit({"foo" => "yyy", "zabbix_host" => "alternative-hostname"}, now)
      d.emit({"f1" => 0.000001}, now)
      d.emit({"f2" => 0.01}, now)
      sleep 1

      $server.stop
      assert_equal open($dir + "/trapper.log").read, <<END
host:test_host	key:test.foo	value:test value of foo	clock:#{now}
host:test_host	key:test.bar	value:test value of bar	clock:#{now}
host:test_host	key:test.baz	value:123.4567	clock:#{now}
host:test_host	key:test.foo	value:yyy	clock:#{now}
host:test_host	key:test.f1	value:0.0	clock:#{now}
host:test_host	key:test.f2	value:0.01	clock:#{now}
END
    end
  end

  CONFIG_HOST_KEY = %[
    zabbix_server  127.0.0.1
    host           test_host
    host_key       host
    add_key_prefix test
    name_keys      foo, bar, baz
  ]

  def create_driver_host_key(conf = CONFIG_HOST_KEY, tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::ZabbixOutput, tag).configure(conf)
  end

  CONFIG_PREFIX_KEY = %[
    zabbix_server  127.0.0.1
    host           test_host
    prefix_key     prefix
    name_keys      foo, bar, baz
  ]

  def create_driver_prefix_key(conf = CONFIG_PREFIX_KEY, tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::ZabbixOutput, tag).configure(conf)
  end

  def test_write_host_key
    d = create_driver_host_key
    now = Time.now.to_i
    if ENV['LIVE_TEST']
      d.emit({"foo" => "AAA" }, now)
      d.emit({"foo" => "BBB", "host" => "alternative-hostname"}, now)
      d.run
      sleep 1

      $server.stop
      assert_equal open($dir + "/trapper.log").read, <<END
host:test_host	key:test.foo	value:AAA	clock:#{now}
host:alternative-hostname	key:test.foo	value:BBB	clock:#{now}
END
    end
  end

  def test_write_prefix_key
    d = create_driver_prefix_key
    now = Time.now.to_i
    if ENV['LIVE_TEST']
      d.emit({"foo" => "AAA"}, now)
      d.emit({"foo" => "BBB", "prefix" => "p"}, now)
      d.run
      sleep 1
      $server.stop
      assert_equal open($dir + "/trapper.log").read, <<END
host:test_host	key:foo	value:AAA	clock:#{now}
host:test_host	key:p.foo	value:BBB	clock:#{now}
END
    end
  end

end
