require 'helper'

class ZabbixOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    zabbix_server  127.0.0.1
    host           clienthost
    add_key_prefix test
    name_keys      foo, bar, baz
  ]

  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::ZabbixOutput, tag).configure(conf)
  end

  def test_write
#    d = create_driver
#    d.emit({"foo" => "test value of foo"})
#    d.emit({"bar" => "test value of bar"})
#    d.emit({"baz" => rand * 10 }) 
  end
end
