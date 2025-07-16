import { useAppContext } from "../context/appContext";

export const useIsConnected = () => {
  const { address, status } = useAppContext();
  console.log(address,status)
  return Boolean(address && status === "connected");
};
