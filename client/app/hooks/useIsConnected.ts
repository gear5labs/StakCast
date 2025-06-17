import { useAppContext } from "../context/appContext";

export const useIsConnected = () => {
  const { address, status } = useAppContext();
  if (!address && status !== "connected") {
    return false;
  }
  return true;
};
