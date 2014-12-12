package main

import (
	"log"

	"github.com/fujiwara/go-zabbix-get/zabbix"
)

func main() {
	err := zabbix.RunTrapperServer(
		"127.0.0.1:10051",
		func(req zabbix.TrapperRequest) (res zabbix.TrapperResponse, err error) {
			log.Printf("%#v", req)
			res.Proceeded = len(req.Data)
			return res, nil
		},
	)
	if err != nil {
		panic(err)
	}
}
