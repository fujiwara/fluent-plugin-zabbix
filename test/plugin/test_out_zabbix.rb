require 'helper'

if ENV['LIVE_TEST']
  require "glint"
  require "tmpdir"
  system "go", "build", "test/mockserver.go"
end

class ZabbixOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
    if ENV['LIVE_TEST']
      $dir = Dir.mktmpdir
      $server = Glint::Server.new(10051, { :timeout => 3 }) do |port|
        exec "./mockserver", $dir.to_s + "/trapper.log"
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
    if ENV['LIVE_TEST']
      d.emit({"foo" => "test value of foo"})
      d.emit({"bar" => "test value of bar"})
      d.emit({"baz" => 123.4567 })
      d.emit({"foo" => "yyy", "zabbix_host" => "alternative-hostname"})
      d.emit({"f1" => 0.000001})
      d.emit({"f2" => 0.01})
      d.run
      sleep 1
      $server.stop
      assert_equal open($dir + "/trapper.log").read, <<END
host:test_host	key:test.foo	value:test value of foo
host:test_host	key:test.bar	value:test value of bar
host:test_host	key:test.baz	value:123.4567
host:test_host	key:test.foo	value:yyy
host:test_host	key:test.f1	value:0.0
host:test_host	key:test.f2	value:0.01
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
    if ENV['LIVE_TEST']
      d.emit({"foo" => "AAA" })
      d.emit({"foo" => "BBB", "host" => "alternative-hostname"})
      d.run
      sleep 1
      $server.stop
      assert_equal open($dir + "/trapper.log").read, <<END
host:test_host	key:test.foo	value:AAA
host:alternative-hostname	key:test.foo	value:BBB
END
    end
  end

  def test_write_prefix_key
    d = create_driver_prefix_key
    if ENV['LIVE_TEST']
      d.emit({"foo" => "AAA"})
      d.emit({"foo" => "BBB", "prefix" => "p"})
      d.run
      sleep 1
      $server.stop
      assert_equal open($dir + "/trapper.log").read, <<END
host:test_host	key:foo	value:AAA
host:test_host	key:p.foo	value:BBB
END
    end
  end

end
