# fluent-plugin-zabbix

## Component

### ZabbixOutput

Plugin to output values to Zabbix server.

## Configuration

### ZabbixOutput

Zabbix configuration of Item:

    Key: metrics.field1
    Type: Zabbix trapper

    Key: metrics.field2
    Type: Zabbix trapper

For messages such as:
    tag:metrics {"metrics.field1":300, "metrics.field2":20}

    <match metrics>
      @type zabbix
      zabbix_server 192.168.0.1
      port          10051
      host          client-hostname
      name_keys     metrics.field1,metrics.field2
    </match>

or, use `add_key_prefix`
    tag:metrics {"field1":300, "field2":20}

    <match metrics>
      @type zabbix
      zabbix_server     192.168.0.1
      port              10051
      host              client-hostname
      add_key_prefix    metrics
      name_key_pattern  ^field
    </match>

If `prefix_key` is specified, a value of record[prefix_key] will be used as key prefix.


If you want to specify the host(on zabbix) from record's value, use "host_key" directive.

    tag:metrics {"zabbix_host":"myhostname", "metrics.field1":300, "metrics.field2":20}

    <match metrics>
      @type zabbix
      zabbix_server 192.168.0.1
      host_key      zabbix_host
      name_keys     metrics.field1,metrics.field2
    </match>

v0.0.7~ includes [Fluent::Mixin::ConfigPlaceholders](https://github.com/tagomoris/fluent-mixin-config-placeholders). Placeholders will be expanded in a configuration.

```
<match matrics.**>
  @type            zabbix
  zabbix_server    192.168.0.1
  host             ${hostname}
  add_key_prefix   ${tag}
  name_key_pattern .
</match>
```

`host` parameter is set by default to Ruby's `Socket.gethostname` if not specified.

# TODO

- patches welcome!

## Copyright

- Copyright: Copyright (c) 2012- FUJIWARA Shunichiro
- License:   Apache License, Version 2.0
