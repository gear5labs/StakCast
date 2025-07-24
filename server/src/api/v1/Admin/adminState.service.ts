import { Contract, RpcProvider } from 'starknet';

class AdminStateService {
  private static instance: AdminStateService;
  private provider: RpcProvider;
  private contract: Contract;
  private state: any = {
    paused: null,
    platformFee: null,
    protocolToken: null,
    lastUpdated: null
  };
  private pollInterval: NodeJS.Timeout | null = null;

  private constructor() {
    const nodeUrl = process.env.NEXT_PUBLIC_RPC_URL || 'https://starknet-sepolia.public.blastapi.io';
    const contractAddress = '0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534';
    const abi = [
      { name: 'is_paused', type: 'function', inputs: [], outputs: [{ type: 'core::bool' }] },
      { name: 'get_platform_fee', type: 'function', inputs: [], outputs: [{ type: 'core::integer::u256' }] },
      { name: 'get_protocol_token', type: 'function', inputs: [], outputs: [{ type: 'core::starknet::contract_address::ContractAddress' }] }
    ];
    this.provider = new RpcProvider({ nodeUrl });
    this.contract = new Contract(abi, contractAddress, this.provider);
    this.startPolling();
  }

  static getInstance(): AdminStateService {
    if (!AdminStateService.instance) {
      AdminStateService.instance = new AdminStateService();
    }
    return AdminStateService.instance;
  }

  private async pollState() {
    try {
      const [paused, platformFee, protocolToken] = await Promise.all([
        this.contract.is_paused(),
        this.contract.get_platform_fee(),
        this.contract.get_protocol_token()
      ]);
      this.state = {
        paused: paused[0] === 1,
        platformFee: platformFee[0],
        protocolToken: protocolToken[0],
        lastUpdated: new Date().toISOString()
      };
    } catch (err) {
      // Optionally log error
    }
  }

  private startPolling() {
    this.pollState();
    this.pollInterval = setInterval(() => this.pollState(), 15000); // poll every 15s
  }

  getState() {
    return this.state;
  }
}

export default AdminStateService;
