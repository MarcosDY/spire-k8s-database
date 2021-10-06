package main

import (
	"api/pkg/service"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strconv"

	"github.com/gorilla/mux"
	"github.com/hashicorp/hcl"
)

var (
	configFilePath = flag.String("config", "service.conf", "Path to configuration file")
)

type config struct {
	Host      string `hcl:"host"`
	Port      int    `hcl:"port"`
	DBHost    string `hcl:"db_host"`
	DBPort    string `hcl:"db_port"`
	DBUser    string `hcl:"db_user"`
	DBName    string `hcl:"db_name"`
	AgentSock string `hcl:"agent_sock"`
}

func parseConfigFile(filePath string) (*config, error) {
	data, err := ioutil.ReadFile(filePath)
	if err != nil {
		if os.IsNotExist(err) {
			msg := "could not find config file %q: please use the -config flag"
			p, err := filepath.Abs(filePath)
			if err != nil {
				p = filePath
				msg = "config file not found at %q: use -config"
			}
			return nil, fmt.Errorf(msg, p)
		}
		return nil, err
	}

	c := new(config)
	if err := hcl.Decode(c, string(data)); err != nil {
		return nil, fmt.Errorf("unable to decode configuration: %v", err)
	}
	return c, nil
}

func main() {
	flag.Parse()

	c, err := parseConfigFile(*configFilePath)
	if err != nil {
		log.Fatalf("Error parsing configuration file: %v", err)
	}

	connStr := fmt.Sprintf("host=%s port=%s user=%s dbname=%s sslcert=%s sslkey=%s sslrootcert=%s",
		c.DBHost, c.DBPort, c.DBUser, c.DBName, "svid.pem", "svid.key", "bundle.pem")
	handler := service.NewHandler(connStr, c.AgentSock)

	router := mux.NewRouter().StrictSlash(true)
	router.HandleFunc("/customers", handler.CustomersList)
	router.HandleFunc("/customer/insert", handler.CustomerInsert)
	log.Println("Service starting")
	log.Fatal(http.ListenAndServe(net.JoinHostPort(c.Host, strconv.Itoa(c.Port)), router))
}
