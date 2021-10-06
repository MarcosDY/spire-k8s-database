package customer

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
)

type InsertCustomerCmd struct {
	commonCmd

	Name    string `short:"n" help:"Customer name."`
	Address string `short:"a" help:"Customer address."`
}

func (c *InsertCustomerCmd) Run() error {
	jsonData, err := json.Marshal(&Customer{
		Name:    c.Name,
		Address: c.Address,
	})
	if err != nil {
		return fmt.Errorf("failed to parse json: %w", err)
	}

	resp, err := http.Post(c.ApiURL+"/customer/insert", "application/json", bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to call post: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}
	resp.Body.Close()

	log.Println("Customer created!!!")
	return nil
}
