import { useEffect, useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Bot,
  Check,
  ChevronDown,
  LoaderCircle,
  Send,
  ShieldCheck,
  Sparkles,
  Trash2,
  X,
} from "lucide-react";
import {
  chatWithAssistant,
  deleteAssistantHistory,
  executeAssistantAction,
  getAssistantPrivacy,
  updateAssistantPrivacy,
  type AssistantApiMessage,
  type AssistantProposedAction,
  type AssistantRole,
} from "@/api/assistant.api";
import { lunchKeys } from "@/api/lunch.api";
import { getApiErrorMessage } from "@/lib/format";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";

type UiMessage = {
  id: string;
  role: AssistantRole;
  content: string;
  action?: AssistantProposedAction;
  actionStatus?: "pending" | "completed" | "dismissed";
};

const greeting: UiMessage = {
  id: "assistant-greeting",
  role: "assistant",
  content:
    "Chào bạn, tôi là FitTrack PT. Tôi có thể tư vấn theo hồ sơ, món ăn và bài tập hiện có; đồng thời chuẩn bị buổi tập, bữa ăn hoặc đơn cơm để bạn xác nhận.",
};

export default function AssistantChat() {
  const queryClient = useQueryClient();
  const [open, setOpen] = useState(false);
  const [input, setInput] = useState("");
  const [messages, setMessages] = useState<UiMessage[]>([greeting]);
  const [showPrivacy, setShowPrivacy] = useState(false);
  const endRef = useRef<HTMLDivElement>(null);

  const privacyQuery = useQuery({
    queryKey: ["assistant-privacy"],
    queryFn: getAssistantPrivacy,
    enabled: open,
  });

  const privacyMutation = useMutation({
    mutationFn: updateAssistantPrivacy,
    onSuccess: (privacy) => {
      queryClient.setQueryData(["assistant-privacy"], privacy);
      setShowPrivacy(!privacy.consented);
      if (!privacy.consented) setMessages([greeting]);
    },
  });

  const clearHistoryMutation = useMutation({
    mutationFn: deleteAssistantHistory,
    onSuccess: () => setMessages([greeting]),
  });

  useEffect(() => {
    if (open) {
      endRef.current?.scrollIntoView({ behavior: "smooth" });
    }
  }, [messages, open]);

  const chatMutation = useMutation({
    mutationFn: chatWithAssistant,
    onSuccess: (response) => {
      setMessages((current) => [
        ...current,
        {
          id: crypto.randomUUID(),
          role: "assistant",
          content: response.reply,
          action: response.proposedAction ?? undefined,
          actionStatus: response.proposedAction ? "pending" : undefined,
        },
      ]);
    },
    onError: (error) => {
      setMessages((current) => [
        ...current,
        {
          id: crypto.randomUUID(),
          role: "assistant",
          content: getApiErrorMessage(
            error,
            "Tôi chưa thể kết nối tới dịch vụ AI. Vui lòng thử lại.",
          ),
        },
      ]);
    },
  });

  const executeMutation = useMutation({
    mutationFn: ({
      messageId,
      action,
    }: {
      messageId: string;
      action: AssistantProposedAction;
    }) => executeAssistantAction(action).then((result) => ({ messageId, result })),
    onSuccess: ({ messageId, result }) => {
      setMessages((current) => [
        ...current.map((message) =>
          message.id === messageId
            ? { ...message, actionStatus: "completed" as const }
            : message,
        ),
        {
          id: crypto.randomUUID(),
          role: "assistant",
          content: `${result.message}. Dữ liệu trên các trang liên quan đã được cập nhật.`,
        },
      ]);
      invalidateApplicationData();
    },
    onError: (error) => {
      setMessages((current) => [
        ...current,
        {
          id: crypto.randomUUID(),
          role: "assistant",
          content: getApiErrorMessage(
            error,
            "Không thể thực hiện thao tác. Dữ liệu chưa bị thay đổi.",
          ),
        },
      ]);
    },
  });

  const invalidateApplicationData = () => {
    const keys: (readonly unknown[])[] = [
      ["workout-sessions"],
      ["meal-logs"],
      ["dashboard-today"],
      ["dashboard-progress"],
      ["weekly-report"],
      ["weekly-recommendations"],
      ["achievements"],
      lunchKeys.today(),
      lunchKeys.history(),
      lunchKeys.transactions(),
    ];
    keys.forEach((queryKey) => {
      void queryClient.invalidateQueries({ queryKey });
    });
  };

  const sendMessage = () => {
    const content = input.trim();
    if (!privacyQuery.data?.consented || !content || chatMutation.isPending) {
      return;
    }
    const userMessage: UiMessage = {
      id: crypto.randomUUID(),
      role: "user",
      content,
    };
    const nextMessages = [...messages, userMessage];
    setMessages(nextMessages);
    setInput("");

    const apiMessages: AssistantApiMessage[] = nextMessages
      .map(({ role, content: messageContent }) => ({
        role,
        content: messageContent,
      }))
      .slice(-20);
    chatMutation.mutate(apiMessages);
  };

  const dismissAction = (messageId: string) => {
    setMessages((current) =>
      current.map((message) =>
        message.id === messageId
          ? { ...message, actionStatus: "dismissed" }
          : message,
      ),
    );
  };

  return (
    <>
      {open && (
        <section
          aria-label="FitTrack PT"
          className="fixed bottom-24 right-4 z-50 flex h-[min(680px,calc(100vh-8rem))] w-[min(420px,calc(100vw-2rem))] flex-col overflow-hidden rounded-3xl border border-emerald-900/10 bg-background shadow-2xl shadow-emerald-950/20"
        >
          <header className="flex items-center gap-3 bg-[#0c2821] px-4 py-3.5 text-white">
            <span className="grid size-10 place-items-center rounded-2xl bg-emerald-400 text-[#0c2821]">
              <Bot className="size-5" />
            </span>
            <div className="min-w-0 flex-1">
              <h2 className="font-semibold">FitTrack PT</h2>
              <p className="text-xs text-emerald-100/60">Tư vấn và thao tác có xác nhận</p>
            </div>
            <Button
              type="button"
              variant="ghost"
              size="icon"
              className="text-white hover:bg-white/10 hover:text-white"
              onClick={() => setShowPrivacy((value) => !value)}
              aria-label="Quyền riêng tư của trợ lý AI"
              title="Quyền riêng tư"
            >
              <ShieldCheck />
            </Button>
            <Button
              type="button"
              variant="ghost"
              size="icon"
              className="text-white hover:bg-white/10 hover:text-white"
              onClick={() => setOpen(false)}
              aria-label="Đóng chatbot"
            >
              <ChevronDown />
            </Button>
          </header>

          <div className="flex-1 space-y-4 overflow-y-auto bg-muted/25 p-4">
            {(showPrivacy || privacyQuery.data?.consented === false) && (
              <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-950">
                <div className="flex items-center gap-2 font-semibold">
                  <ShieldCheck className="size-4" />
                  Quyền riêng tư và dữ liệu AI
                </div>
                <p className="mt-2 leading-5">
                  FitTrack chỉ gửi dữ liệu cần thiết cho câu hỏi hiện tại tới Gemini. Không gửi email
                  hoặc tên của bạn.
                </p>
                <ul className="mt-2 list-disc space-y-1 pl-5 text-xs leading-5">
                  {(privacyQuery.data?.dataCategories ?? []).map((category) => (
                    <li key={category}>{category}</li>
                  ))}
                </ul>
                <p className="mt-2 text-xs leading-5 text-emerald-900/75">
                  {privacyQuery.data?.retentionPolicy}
                </p>
                <div className="mt-3 flex flex-wrap gap-2">
                  {privacyQuery.data?.consented ? (
                    <Button
                      type="button"
                      size="sm"
                      variant="destructive"
                      disabled={privacyMutation.isPending}
                      onClick={() => privacyMutation.mutate(false)}
                    >
                      Tắt trợ lý AI
                    </Button>
                  ) : (
                    <Button
                      type="button"
                      size="sm"
                      disabled={privacyMutation.isPending || privacyQuery.isLoading}
                      onClick={() => privacyMutation.mutate(true)}
                    >
                      Tôi đồng ý và tiếp tục
                    </Button>
                  )}
                  <Button
                    type="button"
                    size="sm"
                    variant="outline"
                    disabled={clearHistoryMutation.isPending}
                    onClick={() => clearHistoryMutation.mutate()}
                  >
                    <Trash2 />
                    Xóa cuộc trò chuyện
                  </Button>
                </div>
              </div>
            )}
            {privacyQuery.data?.consented && !showPrivacy && messages.map((message) => (
              <div
                key={message.id}
                className={message.role === "user" ? "flex justify-end" : "flex justify-start"}
              >
                <div
                  className={
                    message.role === "user"
                      ? "max-w-[85%] rounded-2xl rounded-br-md bg-emerald-700 px-3.5 py-2.5 text-sm leading-6 text-white"
                      : "max-w-[92%] rounded-2xl rounded-bl-md border bg-background px-3.5 py-2.5 text-sm leading-6"
                  }
                >
                  <p className="whitespace-pre-wrap">{message.content}</p>
                  {message.action && (
                    <ActionConfirmation
                      message={message}
                      busy={executeMutation.isPending}
                      onConfirm={() =>
                        executeMutation.mutate({
                          messageId: message.id,
                          action: message.action!,
                        })
                      }
                      onDismiss={() => dismissAction(message.id)}
                    />
                  )}
                </div>
              </div>
            ))}

            {privacyQuery.data?.consented && !showPrivacy && chatMutation.isPending && (
              <div className="flex justify-start">
                <div className="flex items-center gap-2 rounded-2xl rounded-bl-md border bg-background px-3.5 py-2.5 text-sm text-muted-foreground">
                  <LoaderCircle className="size-4 animate-spin" />
                  Đang phân tích dữ liệu của bạn...
                </div>
              </div>
            )}
            <div ref={endRef} />
          </div>

          <footer className="border-t bg-background p-3">
            <div className="flex items-end gap-2 rounded-2xl border bg-muted/25 p-2">
              <textarea
                value={input}
                onChange={(event) => setInput(event.target.value)}
                onKeyDown={(event) => {
                  if (event.key === "Enter" && !event.shiftKey) {
                    event.preventDefault();
                    sendMessage();
                  }
                }}
                rows={2}
                maxLength={4_000}
                disabled={!privacyQuery.data?.consented}
                placeholder="Ví dụ: Tạo buổi tập chân 45 phút hôm nay..."
                className="min-h-12 flex-1 resize-none bg-transparent px-2 py-1.5 text-sm outline-none placeholder:text-muted-foreground"
              />
              <Button
                type="button"
                size="icon"
                onClick={sendMessage}
                disabled={!privacyQuery.data?.consented || !input.trim() || chatMutation.isPending}
                aria-label="Gửi tin nhắn"
              >
                <Send />
              </Button>
            </div>
            <p className="mt-2 text-center text-[0.65rem] text-muted-foreground">
              {privacyQuery.data?.consented
                ? "AI có thể sai. Hãy kiểm tra đề xuất trước khi xác nhận."
                : "Bạn cần đồng ý với phạm vi dữ liệu trước khi gửi tin nhắn."}
            </p>
          </footer>
        </section>
      )}

      <Button
        type="button"
        size="lg"
        onClick={() => setOpen((value) => !value)}
        className="fixed bottom-5 right-4 z-50 h-14 rounded-2xl bg-[#0c2821] px-4 text-white shadow-xl shadow-emerald-950/25 hover:bg-[#123a30]"
        aria-expanded={open}
        aria-label={open ? "Đóng FitTrack PT" : "Mở FitTrack PT"}
      >
        {open ? <X /> : <Sparkles />}
        <span className="hidden sm:inline">FitTrack PT</span>
      </Button>
    </>
  );
}

function ActionConfirmation({
  message,
  busy,
  onConfirm,
  onDismiss,
}: {
  message: UiMessage;
  busy: boolean;
  onConfirm: () => void;
  onDismiss: () => void;
}) {
  if (!message.action) {
    return null;
  }

  return (
    <div className="mt-3 rounded-xl border border-emerald-200 bg-emerald-50 p-3 text-emerald-950">
      <div className="flex items-center gap-2">
        <Sparkles className="size-4" />
        <p className="font-semibold">{message.action.summary}</p>
      </div>

      {message.actionStatus === "completed" ? (
        <Badge className="mt-3 bg-emerald-700 text-white">
          <Check />
          Đã thực hiện
        </Badge>
      ) : message.actionStatus === "dismissed" ? (
        <Badge variant="outline" className="mt-3">
          Đã bỏ qua
        </Badge>
      ) : (
        <div className="mt-3 flex gap-2">
          <Button type="button" size="sm" onClick={onConfirm} disabled={busy}>
            {busy ? <LoaderCircle className="animate-spin" /> : <Check />}
            Xác nhận
          </Button>
          <Button type="button" size="sm" variant="outline" onClick={onDismiss} disabled={busy}>
            Bỏ qua
          </Button>
        </div>
      )}
    </div>
  );
}
