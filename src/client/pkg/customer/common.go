package customer

type Cmd struct {
	List   ListCustomerCmd   `cmd:"" help:"List customers."`
	Insert InsertCustomerCmd `cmd:"" help:"Insert customer."`
}

type commonCmd struct {
	ApiURL string `short:"api" help:"Api URL" default:"http://localhost:9001"`
}

type ListResponse struct {
	Customers []*Customer `json:"customers"`
}

type Customer struct {
	Name    string `json:"name"`
	Address string `json:"address"`
}
