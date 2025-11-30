package repository

import (
	"database/sql"
	"fmt"
	"log"
	"time"
)

type DBConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	Database string
}

func NewDB(cfg DBConfig) (*sql.DB, error) {
	dns := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true",
		cfg.User,
		cfg.Password,
		cfg.Host,
		cfg.Port,
		cfg.Database,
	)
	db, err := sql.Open("mysql", dns)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	log.Println("Connected to the database successfully")
	return db, nil

}


func InitSchema(db *sql.DB) error {
	schema := []string{
		`CREATE TABLE IF NOT EXISTS tasks (
			id VARCHAR(36) PRIMARY KEY,
			name VARCHAR(100) NOT NULL,
			payload JSON,
			priority INT DEFAULT 0,
			status ENUM('pending', 'running', 'completed', 'failed') DEFAULT 'pending',
			result JSON,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			INDEX idx_status (status),
			INDEX idx_priority (priority),
			INDEX idx_created_at (created_at)
		)`,
		`CREATE TABLE IF NOT EXISTS workers (
			worker_id VARCHAR(50) PRIMARY KEY,
			capabilities JSON,
			last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			INDEX idx_last_seen (last_seen)
		)`,
	}

	for _, stmt := range schema {
		if _, err := db.Exec(stmt); err != nil {
			return fmt.Errorf("failed to execute statement: %w", err)
		}
	}

	log.Println("Database schema initialized successfully")
	return nil
}

