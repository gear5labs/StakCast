import { useAppContext } from "../context/appContext";

export const useIsConnected = () => {
  const { address, status } = useAppContext();
  console.log(address, status);
  if (!address && status === "disconnected") {
    return false;
  }
  return true;
};
