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
  config_param :name_keys, :string,        :default => nil
  config_param :name_key_pattern, :string, :default => nil
  config_param :add_key_prefix, :string,   :default => nil

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
      @name_keys = @name_keys.split(',')
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

  def send(tag, name, value)
    if @add_key_prefix
      name = "#{@add_key_prefix}.#{name}"
    end
    begin
      zbx = Zabbix::Sender.new(:host => @zabbix_server, :port => @port)
      $log.debug("zabbix: #{zbx}, #{name}: #{value}, host: #{@host}")

      status = zbx.send_data(name, value, { :host => @host })

    rescue IOError, EOFError, SystemCallError
      # server didn't respond
      $log.warn "Zabbix::Sender.send_data raises exception: #{$!.class}, '#{$!.message}'"
      status = false
    end
    unless status
      $log.warn "failed to send to zabbix_server: #{@zabbix_server}:#{@port}, host:#{@host} '#{name}': #{value}"
    end
  end

  def emit(tag, es, chain)
    if @name_keys
      es.each {|time,record|
        @name_keys.each {|name|
          if record[name]
            send(tag, name, record[name])
          end
        }
      }
    else # for name_key_pattern
      es.each {|time,record|
        record.keys.each {|key|
          if @name_key_pattern.match(key) and record[key]
            send(tag, key, record[key])
          end
        }
      }
    end
    chain.next
  end
end