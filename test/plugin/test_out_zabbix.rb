require 'helper'
require 'fluent/test/driver/output'

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
      $server = Glint::Server.new(10051, { timeout: 3 }) do |port|
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

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::ZabbixOutput).configure(conf)
  end

  def test_write
    d = create_driver
    if ENV['LIVE_TEST']
      d.run(default_tag: 'test') do
        d.feed({"foo" => "test value of foo"})
        d.feed({"bar" => "test value of bar"})
        d.feed({"baz" => 123.4567 })
        d.feed({"foo" => "yyy", "zabbix_host" => "alternative-hostname"})
        d.feed({"f1" => 0.000001})
        d.feed({"f2" => 0.01})
        sleep 1
      end
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

  def create_driver_host_key(conf = CONFIG_HOST_KEY)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::ZabbixOutput).configure(conf)
  end

  CONFIG_PREFIX_KEY = %[
    zabbix_server  127.0.0.1
    host           test_host
    prefix_key     prefix
    name_keys      foo, bar, baz
  ]

  def create_driver_prefix_key(conf = CONFIG_PREFIX_KEY)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::ZabbixOutput).configure(conf)
  end

  def test_write_host_key
    d = create_driver_host_key
    if ENV['LIVE_TEST']
      d.run(default_tag: 'test') do
        d.feed({"foo" => "AAA" })
        d.feed({"foo" => "BBB", "host" => "alternative-hostname"})
        sleep 1
      end
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
      d.run(default_tag: 'test') do
        d.feed({"foo" => "AAA"})
        d.feed({"foo" => "BBB", "prefix" => "p"})
        sleep 1
      end
      $server.stop
      assert_equal open($dir + "/trapper.log").read, <<END
host:test_host	key:foo	value:AAA
host:test_host	key:p.foo	value:BBB
END
    end
  end

end
