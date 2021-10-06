package customer

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
)

type ListCustomerCmd struct {
	commonCmd
}

func (c *ListCustomerCmd) Run() error {
	resp, err := http.Get(c.commonCmd.ApiURL + "/customers")
	if err != nil {
		return err
	}

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}
	defer resp.Body.Close()
	listResp := new(ListResponse)
	if err := json.NewDecoder(resp.Body).Decode(listResp); err != nil {
		return fmt.Errorf("failed to decode response: %w", err)
	}

	log.Println("Customers found:")
	for _, eachCustomer := range listResp.Customers {
		log.Printf("Name: %q, Address: %q", eachCustomer.Name, eachCustomer.Address)
	}

	return nil
}
