package service

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	_ "github.com/lib/pq"
	"github.com/spiffe/go-spiffe/v2/workloadapi"
)

type ListResponse struct {
	Customers []*Customer `json:"customers"`
}

type Customer struct {
	Name    string `json:"name"`
	Address string `json:"address"`
}

type Handler struct {
	connStr   string
	agentSock string
}

func NewHandler(connStr string, agentSock string) *Handler {
	return &Handler{
		connStr:   connStr,
		agentSock: agentSock,
	}
}

func (h *Handler) CustomersList(w http.ResponseWriter, r *http.Request) {
	log.Println("List customers called...")
	if r.Method != http.MethodGet {
		log.Printf("Invalid http method: %q", r.Method)
		http.Error(w, "unexpected http method", http.StatusInternalServerError)
		return
	}

	// Attes app and write response on disk
	if err := writeSVIDOnDisk(h.agentSock); err != nil {
		log.Printf("Failed to fetch SVID: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// open database
	db, err := sql.Open("postgres", h.connStr)
	if err != nil {
		log.Printf("Failed to connect database: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// close database
	defer db.Close()
	log.Println("Connection created")

	listResp := new(ListResponse)
	rows, err := db.Query(`SELECT "name", "address" FROM "customers"`)
	if err != nil {
		log.Printf("Error executing query: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	for rows.Next() {
		customer := &Customer{}

		if err := rows.Scan(&customer.Name, &customer.Address); err != nil {
			log.Printf("Error retrieving customer: %v", err)
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		listResp.Customers = append(listResp.Customers, customer)
	}

	if err := json.NewEncoder(w).Encode(listResp); err != nil {
		log.Printf("Error processing payload: %v\n", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func (h Handler) CustomerInsert(w http.ResponseWriter, r *http.Request) {
	log.Println("Insert customers called...")
	if r.Method != http.MethodPost {
		log.Printf("Invalid http method: %q", r.Method)
		http.Error(w, "unexpected http method", http.StatusInternalServerError)
		return
	}
	defer r.Body.Close()
	log.Println("Connection created")

	if err := writeSVIDOnDisk(h.agentSock); err != nil {
		log.Printf("Failed to fetch SVID: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	var customer Customer
	if err := json.NewDecoder(r.Body).Decode(&customer); err != nil {
		log.Printf("Failed to decode request: %v", err)
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	db, err := sql.Open("postgres", h.connStr)
	if err != nil {
		log.Printf("Failed to connect database: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// close database
	defer db.Close()

	insert := `INSERT INTO "customers"("name", "address") VALUES($1, $2)`
	if _, err := db.Exec(insert, customer.Name, customer.Address); err != nil {
		log.Printf("Failed to insert customer: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func writeSVIDOnDisk(agentSock string) error {
	ctx := context.Background()

	// Calling workload API, it is not the best approach, we have watchers to keep SVIDs updated,
	// but wanted to display the most direct way to call it.
	x509SVID, err := workloadapi.FetchX509SVID(ctx, workloadapi.WithAddr(agentSock))
	if err != nil {
		return fmt.Errorf("failed to get SVID: %w", err)
	}

	log.Printf("SVID found: %q", x509SVID.ID.String())
	cert, key, err := x509SVID.Marshal()
	if err != nil {
		return fmt.Errorf("failed to marhal SVID: %w", err)
	}

	if err := writeCertificates("svid.pem", cert); err != nil {
		return fmt.Errorf("failed to write certificates on disk; %w", err)
	}

	if err := writeKey("svid.key", key); err != nil {
		return fmt.Errorf("failed to write key on disk; %w", err)
	}

	bundles, err := workloadapi.FetchX509Bundles(ctx, workloadapi.WithAddr(agentSock))
	if err != nil {
		return fmt.Errorf("failed to fetch bundle: %w", err)
	}

	bundle, err := bundles.GetX509BundleForTrustDomain(x509SVID.ID.TrustDomain())
	if err != nil {
		return fmt.Errorf("failed to get bundle for certificate trustdomain: %w", err)
	}

	bundlePem, err := bundle.Marshal()
	if err != nil {
		return fmt.Errorf("failed to get marshal bundle: %w", err)
	}

	if err := writeCertificates("bundle.pem", bundlePem); err != nil {
		return fmt.Errorf("failed to write bundles on disk; %w", err)
	}

	return nil
}

func writeCertificates(filename string, data []byte) error {
	return os.WriteFile(filename, data, 0644) // nolint: gosec // expected permission for certificates
}

func writeKey(filename string, data []byte) error {
	return os.WriteFile(filename, data, 0600)
}
