require 'helper'

class ZabbixOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    zabbix_server  127.0.0.1
    host           test_host
    add_key_prefix test
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
      d.emit({"baz" => rand * 10 })
      d.emit({"foo" => "yyy", "zabbix_host" => "alternative-hostname"})
      d.emit({"f1" => 0.000001})
      d.emit({"f2" => 0.01})
      d.run
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

  def test_write_host_key
    d = create_driver_host_key
    if ENV['LIVE_TEST']
      d.emit({"foo" => "AAA" })
      d.emit({"foo" => "BBB", "host" => "alternative-hostname"})
      d.run
    end
  end

end
