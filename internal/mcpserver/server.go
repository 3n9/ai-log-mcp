package mcpserver

import (
	"context"
	"log/slog"
	"os"

	"github.com/3n9/ai-agent-telemetry/service"
	"github.com/3n9/ai-agent-telemetry/validate"

	"github.com/modelcontextprotocol/go-sdk/mcp"
)

const (
	defaultAgentName = "unknown-agent"
	defaultModelName = "unknown-model"
)

// New constructs the telemetry MCP server.
func New() *mcp.Server {
	server := mcp.NewServer(
		&mcp.Implementation{Name: "ai-log-mcp", Version: "v0.1.0"},
		&mcp.ServerOptions{
			Instructions: "Use the telemetry tools before meaningful work. Prefer standard vocabulary and use custom_tags only for extra concise context.",
		},
	)

	mcp.AddTool(server, &mcp.Tool{
		Name:        "start_task",
		Description: "Record telemetry for a new top-level task.",
	}, startTask)
	mcp.AddTool(server, &mcp.Tool{
		Name:        "start_subtask",
		Description: "Record telemetry for a subtask linked to a parent task.",
	}, startSubtask)
	mcp.AddTool(server, &mcp.Tool{
		Name:        "log_interruption",
		Description: "Record telemetry when work is blocked or an approach is abandoned.",
	}, logInterruption)

	return server
}

type taskInput struct {
	AgentName         string   `json:"agent_name,omitempty" jsonschema:"telemetry agent identifier; optional if provided via environment"`
	ModelName         string   `json:"model_name,omitempty" jsonschema:"active model name; optional if provided via environment"`
	TaskID            string   `json:"task_id,omitempty" jsonschema:"optional explicit task identifier"`
	WorkType          string   `json:"work_type" jsonschema:"primary work category"`
	SecondaryWorkType string   `json:"secondary_work_type,omitempty" jsonschema:"secondary work category"`
	Language          string   `json:"language,omitempty" jsonschema:"primary language involved"`
	Domain            string   `json:"domain,omitempty" jsonschema:"domain area"`
	CustomTags        []string `json:"custom_tags,omitempty" jsonschema:"up to 5 concise custom tags"`
	Complexity        string   `json:"complexity" jsonschema:"low, medium, or high"`
	Confidence        float64  `json:"confidence" jsonschema:"confidence between 0 and 1"`
	EstimatedTimeMin  int      `json:"estimated_time_min" jsonschema:"estimated task time in minutes"`
	InputTokens       *int     `json:"input_tokens,omitempty" jsonschema:"optional input token count"`
	OutputTokens      *int     `json:"output_tokens,omitempty" jsonschema:"optional output token count"`
	CostEstimate      *float64 `json:"cost_estimate,omitempty" jsonschema:"optional USD cost estimate"`
}

type subtaskInput struct {
	taskInput
	ParentTaskID string `json:"parent_task_id" jsonschema:"parent task identifier"`
}

type interruptionInput struct {
	taskInput
	ParentTaskID string `json:"parent_task_id,omitempty" jsonschema:"optional parent task identifier"`
}

func startTask(_ context.Context, _ *mcp.CallToolRequest, in taskInput) (*mcp.CallToolResult, service.EmitResponse, error) {
	resp, err := emitFromTaskInput(in, "task", nil)
	return nil, resp, err
}

func startSubtask(_ context.Context, _ *mcp.CallToolRequest, in subtaskInput) (*mcp.CallToolResult, service.EmitResponse, error) {
	parentID := stringPtr(in.ParentTaskID)
	resp, err := emitFromTaskInput(in.taskInput, "subtask", parentID)
	return nil, resp, err
}

func logInterruption(_ context.Context, _ *mcp.CallToolRequest, in interruptionInput) (*mcp.CallToolResult, service.EmitResponse, error) {
	resp, err := emitFromTaskInput(in.taskInput, "interruption", stringPtr(in.ParentTaskID))
	return nil, resp, err
}

func emitFromTaskInput(in taskInput, taskType string, parentTaskID *string) (service.EmitResponse, error) {
	slog.Default().Info("MCP tool invoked", "tool", taskType, "task_type", taskType)
	payload := &validate.Payload{
		SchemaVersion:     1,
		TaskID:            stringPtr(in.TaskID),
		AgentName:         firstNonEmpty(in.AgentName, os.Getenv("AI_LOG_AGENT_NAME"), defaultAgentName),
		ModelName:         firstNonEmpty(in.ModelName, os.Getenv("AI_LOG_MODEL_NAME"), defaultModelName),
		WorkType:          in.WorkType,
		SecondaryWorkType: stringPtr(in.SecondaryWorkType),
		Language:          stringPtr(in.Language),
		Domain:            stringPtr(in.Domain),
		CustomTags:        in.CustomTags,
		Complexity:        in.Complexity,
		Confidence:        in.Confidence,
		EstimatedTimeMin:  in.EstimatedTimeMin,
		TaskType:          taskType,
		ParentTaskID:      parentTaskID,
		InputTokens:       in.InputTokens,
		OutputTokens:      in.OutputTokens,
		CostEstimate:      in.CostEstimate,
	}

	resp, err := service.Emit(service.EmitRequest{Payload: payload})
	if err != nil {
		slog.Default().Error("emit failed", "tool", taskType, "error", err)
		return service.EmitResponse{}, err
	}
	return *resp, nil
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if value != "" {
			return value
		}
	}
	return ""
}

func stringPtr(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}
