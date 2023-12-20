package main

import (
	"fmt"
	"io"
	"log"
	"os"

	"github.com/fujiwara/go-zabbix-get/zabbix"
)

var Output io.Writer

func main() {
	var err error
	if len(os.Args) >= 2 {
		Output, err = os.Create(os.Args[1])
		if err != nil {
			panic(err)
		}
		log.Printf("output to %s", os.Args[1])
	} else {
		Output = os.Stdout
	}
	err = zabbix.RunTrapper("127.0.0.1:10051", handler)
	if err != nil {
		panic(err)
	}
}

func handler(req zabbix.TrapperRequest) (res zabbix.TrapperResponse, err error) {
	for _, d := range req.Data {
		line := fmt.Sprintf(
			"host:%s\tkey:%s\tvalue:%s\tclock:%d\n",
			d.Host,
			d.Key,
			d.Value,
			d.Clock,
		)
		Output.Write([]byte(line))
	}
	res.Proceeded = len(req.Data)
	return
}
