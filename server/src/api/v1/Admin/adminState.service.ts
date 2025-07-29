import { Contract, RpcProvider } from 'starknet';
import { injectable } from 'tsyringe';

@injectable()
class AdminStateService {
  private provider: RpcProvider;
  private contract: Contract;
  private state: {
    paused: boolean | null;
    platformFee: string | null;
    protocolToken: string | null;
    lastUpdated: string | null;
  } = {
    paused: null,
    platformFee: null,
    protocolToken: null,
    lastUpdated: null
  };
  private pollInterval: NodeJS.Timeout | null = null;

  public constructor() {
    const { ADMIN_CONTRACT } = require('../../../config/config');
    const abi = [
      { name: 'is_paused', type: 'function', inputs: [], outputs: [{ type: 'core::bool' }] },
      { name: 'get_platform_fee', type: 'function', inputs: [], outputs: [{ type: 'core::integer::u256' }] },
      { name: 'get_protocol_token', type: 'function', inputs: [], outputs: [{ type: 'core::starknet::contract_address::ContractAddress' }] }
    ];
    this.provider = new RpcProvider({ nodeUrl: ADMIN_CONTRACT.nodeUrl });
    this.contract = new Contract(abi, ADMIN_CONTRACT.contractAddress, this.provider);
    this.startPolling();
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
