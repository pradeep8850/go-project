package main

import (
	"go-service/internal/config"
	"go-service/internal/repository"
	server "go-service/pkg"
	"log"

	_ "github.com/go-sql-driver/mysql"

	"github.com/joho/godotenv"
)

func main() {
	err := godotenv.Load(".env")
	if err != nil {
		panic("Error loading .env file")
	}

	dbConfig := repository.DBConfig{
		Host:     config.GetEnv("DB_HOST", "127.0.0.1"),
		Port:     config.GetEnv("DB_PORT", "3306"),
		User:     config.GetEnv("DB_USER", "jobUser"),
		Password: config.GetEnv("MARIADB_ROOT_PASSWORD", ""),
		Database: config.GetEnv("DB_NAME", "jobqueue"),
	}

	db, err := repository.NewDB(dbConfig)

	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	defer db.Close()

	if err := repository.InitSchema(db); err != nil {
		log.Fatalf("Failed to initialize schema: %v", err)
	}

	repository.NewTaskRepository(db)

	router := server.NewServer()
	router.Start(":8080")
}
