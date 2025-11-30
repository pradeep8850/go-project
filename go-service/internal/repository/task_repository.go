package repository

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
)

type Task struct {
    ID        string
    Name      string
    Payload   map[string]interface{}
    Priority  int
    Status    string
    Result    map[string]interface{}
    CreatedAt time.Time
    UpdatedAt time.Time
}

type TaskRepository struct {
    db *sql.DB
}

func NewTaskRepository(db *sql.DB) *TaskRepository {
    return &TaskRepository{db: db}
}

func (r *TaskRepository) CreateTask(name string, payload map[string]interface{}, priority int) (*Task, error) {
    id := uuid.New().String()
    
    payloadJSON, err := json.Marshal(payload)
    if err != nil {
        return nil, fmt.Errorf("failed to marshal payload: %w", err)
    }

    query := `INSERT INTO tasks (id, name, payload, priority, status) VALUES (?, ?, ?, ?, 'pending')`
    _, err = r.db.Exec(query, id, name, payloadJSON, priority)
    if err != nil {
        return nil, fmt.Errorf("failed to create task: %w", err)
    }

    return r.GetTask(id)
}

func (r *TaskRepository) GetTask(id string) (*Task, error) {
    query := `SELECT id, name, payload, priority, status, result, created_at, updated_at FROM tasks WHERE id = ?`
    
    var task Task
    var payloadJSON, resultJSON []byte
    
    err := r.db.QueryRow(query, id).Scan(
        &task.ID,
        &task.Name,
        &payloadJSON,
        &task.Priority,
        &task.Status,
        &resultJSON,
        &task.CreatedAt,
        &task.UpdatedAt,
    )
    
    if err == sql.ErrNoRows {
        return nil, fmt.Errorf("task not found")
    }
    if err != nil {
        return nil, fmt.Errorf("failed to get task: %w", err)
    }

    json.Unmarshal(payloadJSON, &task.Payload)
    if resultJSON != nil {
        json.Unmarshal(resultJSON, &task.Result)
    }

    return &task, nil
}

func (r *TaskRepository) ListTasks(status string, priority *int) ([]*Task, error) {
    query := `SELECT id, name, payload, priority, status, result, created_at, updated_at FROM tasks WHERE 1=1`
    args := []interface{}{}

    if status != "" {
        query += " AND status = ?"
        args = append(args, status)
    }
    if priority != nil {
        query += " AND priority = ?"
        args = append(args, *priority)
    }

    query += " ORDER BY priority ASC, created_at DESC"

    rows, err := r.db.Query(query, args...)
    if err != nil {
        return nil, fmt.Errorf("failed to list tasks: %w", err)
    }
    defer rows.Close()

    var tasks []*Task
    for rows.Next() {
        var task Task
        var payloadJSON, resultJSON []byte

        err := rows.Scan(
            &task.ID,
            &task.Name,
            &payloadJSON,
            &task.Priority,
            &task.Status,
            &resultJSON,
            &task.CreatedAt,
            &task.UpdatedAt,
        )
        if err != nil {
            return nil, fmt.Errorf("failed to scan task: %w", err)
        }

        json.Unmarshal(payloadJSON, &task.Payload)
        if resultJSON != nil {
            json.Unmarshal(resultJSON, &task.Result)
        }

        tasks = append(tasks, &task)
    }

    return tasks, nil
}

func (r *TaskRepository) UpdateTaskStatus(id, status string) error {
    query := `UPDATE tasks SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?`
    _, err := r.db.Exec(query, status, id)
    return err
}

func (r *TaskRepository) DeleteTask(id string) error {
    query := `DELETE FROM tasks WHERE id = ?`
    _, err := r.db.Exec(query, id)
    return err
}
