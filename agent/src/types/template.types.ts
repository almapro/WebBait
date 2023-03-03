import { AgentSocket } from "../agent";

export type AgentTemplateProps = {
  title?: string;
  agentSocket: AgentSocket;
  redirectUrl?: string;
};
