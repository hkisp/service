import ChatClient from "@/components/chat/ChatClient";

export default async function ChatDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return <ChatClient initialId={id} />;
}
