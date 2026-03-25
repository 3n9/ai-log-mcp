package mcpserver

import (
	"database/sql"
	"os"
	"path/filepath"
	"testing"

	_ "modernc.org/sqlite"
)

// setenv sets an env var and returns a cleanup function that restores the previous value.
func setenv(t *testing.T, key, value string) {
	t.Helper()
	prev, hadPrev := os.LookupEnv(key)
	if err := os.Setenv(key, value); err != nil {
		t.Fatalf("os.Setenv(%q): %v", key, err)
	}
	t.Cleanup(func() {
		if hadPrev {
			_ = os.Setenv(key, prev)
		} else {
			_ = os.Unsetenv(key)
		}
	})
}

// openDB opens the SQLite DB at path for read-only verification queries.
func openDB(t *testing.T, path string) *sql.DB {
	t.Helper()
	conn, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatalf("sql.Open: %v", err)
	}
	t.Cleanup(func() { conn.Close() })
	return conn
}

// tempDB creates a temp directory and sets AI_LOG_DB to a file inside it.
func tempDB(t *testing.T) string {
	t.Helper()
	dbPath := filepath.Join(t.TempDir(), "telemetry.db")
	setenv(t, "AI_LOG_DB", dbPath)
	return dbPath
}

func TestNewReturnsServer(t *testing.T) {
	s := New()
	if s == nil {
		t.Fatal("New() returned nil")
	}
}

func TestStartTaskEmitsTask(t *testing.T) {
	dbPath := tempDB(t)

	resp, err := emitFromTaskInput(taskInput{
		AgentName:        "test-agent",
		ModelName:        "test-model",
		WorkType:         "coding",
		Complexity:       "low",
		Confidence:       0.9,
		EstimatedTimeMin: 5,
	}, "task", nil)

	if err != nil {
		t.Fatalf("emitFromTaskInput: %v", err)
	}
	if !resp.OK {
		t.Fatalf("expected OK=true")
	}
	if resp.TaskType != "task" {
		t.Fatalf("expected task_type=task, got %q", resp.TaskType)
	}

	conn := openDB(t, dbPath)
	var taskType string
	if err := conn.QueryRow(`SELECT task_type FROM tasks LIMIT 1`).Scan(&taskType); err != nil {
		t.Fatalf("query task_type: %v", err)
	}
	if taskType != "task" {
		t.Fatalf("expected stored task_type=task, got %q", taskType)
	}
}

func TestStartSubtaskEmitsSubtask(t *testing.T) {
	dbPath := tempDB(t)

	parentID := "parent-001"
	resp, err := emitFromTaskInput(taskInput{
		AgentName:        "test-agent",
		ModelName:        "test-model",
		WorkType:         "coding",
		Complexity:       "low",
		Confidence:       0.8,
		EstimatedTimeMin: 5,
	}, "subtask", &parentID)

	if err != nil {
		t.Fatalf("emitFromTaskInput: %v", err)
	}
	if resp.TaskType != "subtask" {
		t.Fatalf("expected task_type=subtask, got %q", resp.TaskType)
	}
	if resp.ParentTaskID == nil || *resp.ParentTaskID != parentID {
		t.Fatalf("expected parent_task_id=%q, got %v", parentID, resp.ParentTaskID)
	}

	conn := openDB(t, dbPath)
	var storedType, storedParent string
	if err := conn.QueryRow(`SELECT task_type, parent_task_id FROM tasks LIMIT 1`).Scan(&storedType, &storedParent); err != nil {
		t.Fatalf("query row: %v", err)
	}
	if storedType != "subtask" {
		t.Fatalf("expected stored task_type=subtask, got %q", storedType)
	}
	if storedParent != parentID {
		t.Fatalf("expected stored parent_task_id=%q, got %q", parentID, storedParent)
	}
}

func TestLogInterruptionEmitsInterruption(t *testing.T) {
	dbPath := tempDB(t)

	resp, err := emitFromTaskInput(taskInput{
		AgentName:        "test-agent",
		ModelName:        "test-model",
		WorkType:         "analysis",
		Complexity:       "medium",
		Confidence:       0.5,
		EstimatedTimeMin: 10,
	}, "interruption", nil)

	if err != nil {
		t.Fatalf("emitFromTaskInput: %v", err)
	}
	if resp.TaskType != "interruption" {
		t.Fatalf("expected task_type=interruption, got %q", resp.TaskType)
	}

	conn := openDB(t, dbPath)
	var taskType string
	if err := conn.QueryRow(`SELECT task_type FROM tasks LIMIT 1`).Scan(&taskType); err != nil {
		t.Fatalf("query task_type: %v", err)
	}
	if taskType != "interruption" {
		t.Fatalf("expected stored task_type=interruption, got %q", taskType)
	}
}

func TestAgentNameFallsBackToEnvVar(t *testing.T) {
	dbPath := tempDB(t)
	setenv(t, "AI_LOG_AGENT_NAME", "env-agent")

	_, err := emitFromTaskInput(taskInput{
		// AgentName intentionally empty
		ModelName:        "test-model",
		WorkType:         "coding",
		Complexity:       "low",
		Confidence:       0.9,
		EstimatedTimeMin: 5,
	}, "task", nil)
	if err != nil {
		t.Fatalf("emitFromTaskInput: %v", err)
	}

	conn := openDB(t, dbPath)
	var agentName string
	if err := conn.QueryRow(`SELECT agent_name FROM tasks LIMIT 1`).Scan(&agentName); err != nil {
		t.Fatalf("query agent_name: %v", err)
	}
	if agentName != "env-agent" {
		t.Fatalf("expected agent_name=env-agent, got %q", agentName)
	}
}

func TestModelNameFallsBackToEnvVar(t *testing.T) {
	dbPath := tempDB(t)
	setenv(t, "AI_LOG_MODEL_NAME", "env-model")

	_, err := emitFromTaskInput(taskInput{
		AgentName: "test-agent",
		// ModelName intentionally empty
		WorkType:         "coding",
		Complexity:       "low",
		Confidence:       0.9,
		EstimatedTimeMin: 5,
	}, "task", nil)
	if err != nil {
		t.Fatalf("emitFromTaskInput: %v", err)
	}

	conn := openDB(t, dbPath)
	var modelName string
	if err := conn.QueryRow(`SELECT model_name FROM tasks LIMIT 1`).Scan(&modelName); err != nil {
		t.Fatalf("query model_name: %v", err)
	}
	if modelName != "env-model" {
		t.Fatalf("expected model_name=env-model, got %q", modelName)
	}
}
