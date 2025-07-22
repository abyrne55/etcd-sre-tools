package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
)

type QueryResponse struct {
	Success bool   `json:"success"`
	Result  string `json:"result"`
	Error   string `json:"error,omitempty"`
}

func executeQuery(sqlQuery, snapshotPath string) (*QueryResponse, error) {
	// Clean up the query - don't modify paths, just pass the query as-is
	// The query should already have the correct path from the CLI

	// Execute octosql command
	cmd := exec.Command("octosql", sqlQuery)
	cmd.Env = os.Environ()

	output, err := cmd.CombinedOutput()
	if err != nil {
		return &QueryResponse{
			Success: false,
			Error:   fmt.Sprintf("Query failed: %v\nOutput: %s", err, string(output)),
		}, nil
	}

	return &QueryResponse{
		Success: true,
		Result:  string(output),
	}, nil
}

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s <command> [args...]\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "Commands:\n")
		fmt.Fprintf(os.Stderr, "  query <sql> <snapshot_path> - Execute SQL query on etcd snapshot\n")
		fmt.Fprintf(os.Stderr, "  interactive <snapshot_path>  - Start interactive mode\n")
		fmt.Fprintf(os.Stderr, "  tools                       - List available tools\n")
		os.Exit(1)
	}

	command := os.Args[1]

	switch command {
	case "query":
		if len(os.Args) < 4 {
			fmt.Fprintf(os.Stderr, "Usage: %s query <sql> <snapshot_path>\n", os.Args[0])
			os.Exit(1)
		}

		sqlQuery := os.Args[2]
		snapshotPath := os.Args[3]

		response, err := executeQuery(sqlQuery, snapshotPath)
		if err != nil {
			log.Fatalf("Query failed: %v", err)
		}

		output, _ := json.Marshal(response)
		fmt.Println(string(output))

	case "interactive":
		if len(os.Args) < 3 {
			fmt.Fprintf(os.Stderr, "Usage: %s interactive <snapshot_path>\n", os.Args[0])
			os.Exit(1)
		}

		snapshotPath := os.Args[2]

		fmt.Println("🎯 Interactive etcd Analysis")
		fmt.Printf("📁 Snapshot: %s\n", snapshotPath)
		fmt.Println("💡 Enter SQL queries or 'exit' to quit")
		fmt.Println()

		scanner := bufio.NewScanner(os.Stdin)
		for {
			fmt.Print("etcd> ")
			if !scanner.Scan() {
				break
			}

			query := strings.TrimSpace(scanner.Text())
			if query == "exit" || query == "quit" {
				break
			}

			if query == "" {
				continue
			}

			response, err := executeQuery(query, snapshotPath)
			if err != nil {
				fmt.Printf("Error: %v\n", err)
				continue
			}

			if response.Success {
				fmt.Println(response.Result)
			} else {
				fmt.Printf("Error: %s\n", response.Error)
			}
			fmt.Println()
		}

	case "tools":
		fmt.Println("Available Tools:")
		fmt.Println("  - analyze_etcd_snapshot: Execute SQL queries on etcd snapshots")
		fmt.Println("  - query_etcd_resources: Query Kubernetes resources from etcd")
		fmt.Println("  - get_cluster_metadata: Get cluster metadata and health info")

	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", command)
		os.Exit(1)
	}
}
