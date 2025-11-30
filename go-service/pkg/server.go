package pkg

import (
	api_server "go-service/internal/api/client/generated"
	"log"
	"net/http"

	"github.com/go-chi/chi/v5"
)

type Server struct {
	Router *chi.Mux
}

// DeleteTasksTaskId implements api.ServerInterface.
func (s *Server) DeleteTasksTaskId(w http.ResponseWriter, r *http.Request, taskId string) {
	panic("unimplemented")
}

// GetQueueStatus implements api.ServerInterface.
func (s *Server) GetQueueStatus(w http.ResponseWriter, r *http.Request) {
	panic("unimplemented")
}

// GetTasks implements api.ServerInterface.
func (s *Server) GetTasks(w http.ResponseWriter, r *http.Request, params api_server.GetTasksParams) {
	panic("unimplemented")
}

// GetTasksTaskId implements api.ServerInterface.
func (s *Server) GetTasksTaskId(w http.ResponseWriter, r *http.Request, taskId string) {
	panic("unimplemented")
}

// GetWorkers implements api.ServerInterface.
func (s *Server) GetWorkers(w http.ResponseWriter, r *http.Request) {
	panic("unimplemented")
}

// PostTasks implements api.ServerInterface.
func (s *Server) PostTasks(w http.ResponseWriter, r *http.Request) {
	panic("unimplemented")
}

// PostWorkersRegister implements api.ServerInterface.
func (s *Server) PostWorkersRegister(w http.ResponseWriter, r *http.Request) {
	panic("unimplemented")
}

func NewServer() *Server {
	return &Server{
		Router: chi.NewRouter(),
	}
}

func (s *Server) Start(address string) error {
	api_server.HandlerFromMux(s, s.Router)
	server := &http.Server{
		Addr:    address,
		Handler: s.Router,
	}

	log.Printf("Starting server on %s", address)

	return server.ListenAndServe()
}
