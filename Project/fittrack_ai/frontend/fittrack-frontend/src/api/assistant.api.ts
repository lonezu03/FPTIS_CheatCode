import api from "./axios";

export type AssistantRole = "user" | "assistant";

export type AssistantApiMessage = {
  role: AssistantRole;
  content: string;
};

export type AssistantProposedAction = {
  type: "create_workout_session" | "create_meal_log" | "create_lunch_order";
  arguments: Record<string, unknown>;
  summary: string;
};

export type AssistantChatResponse = {
  reply: string;
  proposedAction: AssistantProposedAction | null;
  model: string;
};

export type AssistantExecuteResponse = {
  type: AssistantProposedAction["type"];
  message: string;
  result: unknown;
};

export async function chatWithAssistant(
  messages: AssistantApiMessage[],
): Promise<AssistantChatResponse> {
  const response = await api.post<AssistantChatResponse>("/assistant/chat", { messages });
  return response.data;
}

export async function executeAssistantAction(
  action: AssistantProposedAction,
): Promise<AssistantExecuteResponse> {
  const response = await api.post<AssistantExecuteResponse>("/assistant/actions/execute", {
    type: action.type,
    arguments: action.arguments,
  });
  return response.data;
}
