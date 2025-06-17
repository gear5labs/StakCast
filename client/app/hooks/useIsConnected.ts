import { useAppContext } from "../context/appContext";

export const useIsConnected = () => {
  const { address, status ,account} = useAppContext();
  console.log(address,status,account,'from isConnected')
  if (!address && status !== "connected") {
    return false;
  }
  return true;
};
