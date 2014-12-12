class Fluent::ZabbixOutput < Fluent::Output
  Fluent::Plugin.register_output('zabbix', self)

  def initialize
    super
    require 'zabbix'
    require 'socket'
  end

  config_param :zabbix_server, :string
  config_param :port, :integer,            :default => 10051
  config_param :host, :string,             :default => Socket.gethostname
  config_param :host_key, :string,         :default => nil
  config_param :name_keys, :string,        :default => nil
  config_param :name_key_pattern, :string, :default => nil
  config_param :add_key_prefix, :string,   :default => nil

# Define `log` method for v0.10.42 or earlier
  unless method_defined?(:log)
    define_method("log") { $log }
  end

  def configure(conf)
    super

    if @zabbix_server.nil?
      raise Fluent::ConfigError, "missing zabbix_server"
    end

    if @name_keys.nil? and @name_key_pattern.nil?
      raise Fluent::ConfigError, "missing both of name_keys and name_key_pattern"
    end
    if not @name_keys.nil? and not @name_key_pattern.nil?
      raise Fluent::ConfigError, "cannot specify both of name_keys and name_key_pattern"
    end
    if @name_keys
      @name_keys = @name_keys.split(/ *, */)
    end
    if @name_key_pattern
      @name_key_pattern = Regexp.new(@name_key_pattern)
    end
  end

  def start
    super
  end

  def shutdown
    super
  end

  def send(host, tag, name, value, time)
    if @add_key_prefix
      name = "#{@add_key_prefix}.#{name}"
    end
    begin
      zbx = Zabbix::Sender.new(:host => @zabbix_server, :port => @port)
      log.debug("zabbix: #{zbx}, #{name}: #{value}, host: #{host}, ts: #{time}")
      opts = { :host => host, :ts => time }
      if value.kind_of? Float
        # https://www.zabbix.com/documentation/2.4/manual/config/items/item
        # > Allowed range (for MySQL): -999999999999.9999 to 999999999999.9999 (double(16,4)).
        # > Starting with Zabbix 2.2, receiving values in scientific notation is also supported. E.g. 1e+70, 1e-70.
        status = zbx.send_data(name, value.round(4).to_s, opts)
      else
        status = zbx.send_data(name, value.to_s, opts)
      end
    rescue IOError, EOFError, SystemCallError
      # server didn't respond
      log.warn "plugin-zabbix: Zabbix::Sender.send_data raises exception: #{$!.class}, '#{$!.message}'"
      status = false
    end
    unless status
      log.warn "plugin-zabbix: failed to send to zabbix_server: #{@zabbix_server}:#{@port}, host:#{host} '#{name}': #{value}"
    end
  end

  def emit(tag, es, chain)
    if @name_keys
      es.each {|time,record|
        host = gen_host(record)
        @name_keys.each {|name|
          if record[name]
            send(host, tag, name, record[name], time)
          end
        }
      }
    else # for name_key_pattern
      es.each {|time,record|
        host = gen_host(record)
        record.keys.each {|key|
          if @name_key_pattern.match(key) and record[key]
            send(host, tag, key, record[key], time)
          end
        }
      }
    end
    chain.next
  end

  def gen_host(record)
    if @host_key
      if record[@host_key]
        host = record[@host_key]
      else
        log.warn "plugin-zabbix: host_key is configured '#{@host_key}', but this record has no such key. use host '#{@host}'"
        host = @host
      end
    else
      host = @host
    end
    return host
  end
end
