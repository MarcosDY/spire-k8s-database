package run

import (
	"log"
	"net/http"
)

type Cmd struct {
	Address string `short:"api" help:"Client address" default:":80"`
}

func (c *Cmd) Run() error {
	http.HandleFunc("/", index)

	http.HandleFunc("/healthy", healthy)

	log.Println("Starting service")
	return http.ListenAndServe(c.Address, nil)
}

func index(w http.ResponseWriter, r *http.Request) {
	log.Print("loading index page")
	if r.Method != "GET" {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	w.Write([]byte("Hi!"))
}

func healthy(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	w.WriteHeader(http.StatusOK)
}
