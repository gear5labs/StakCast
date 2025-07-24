import { Account, Contract, RpcProvider, uint256 } from 'starknet';
import { TransactionResult, ContractConfig} from '../../../types/admin.types';

class AdminService {
  private static instance: AdminService;
  private provider: RpcProvider;
  private account: Account;
  private contract: Contract;

  private constructor() {
    const config: ContractConfig = {
      nodeUrl: process.env.NEXT_PUBLIC_RPC_URL || 'https://starknet-sepolia.public.blastapi.io',
      contractAddress: '0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534',
      adminPrivateKey: process.env.ADMIN_PRIVATE_KEY!,
      adminAddress: process.env.ADMIN_ADDRESS!
    };

    this.provider = new RpcProvider({ nodeUrl: config.nodeUrl });
    this.account = new Account(
      this.provider,
      config.adminAddress,
      config.adminPrivateKey
    );

    // Contract ABI
    const abi = [
      {
        name: "pause",
        type: "function",
        inputs: [],
        outputs: []
      },
      {
        name: "unpause",
        type: "function",
        inputs: [],
        outputs: []
      },
      {
        name: "set_platform_fee",
        type: "function",
        inputs: [
          { name: "fee_percentage", type: "core::integer::u256" }
        ],
        outputs: []
      },
      {
        name: "set_protocol_token",
        type: "function",
        inputs: [
          { name: "token_address", type: "core::felt252" }
        ],
        outputs: []
      },
      {
        name: "emergency_close_market",
        type: "function",
        inputs: [
          { name: "market_id", type: "core::felt252" },
          { name: "market_type", type: "core::felt252" }
        ],
        outputs: []
      },
      {
        name: "emergency_withdraw_tokens",
        type: "function",
        inputs: [
          { name: "amount", type: "core::integer::u256" },
          { name: "recipient", type: "core::felt252" }
        ],
        outputs: []
      }
    ];

    this.contract = new Contract(abi, config.contractAddress, this.account);
  }

  static getInstance(): AdminService {
    if (!AdminService.instance) {
      AdminService.instance = new AdminService();
    }
    return AdminService.instance;
  }

  private async executeTransaction(fn: () => Promise<any>): Promise<TransactionResult> {
    try {
      const result = await fn();
      const txHash = result.transaction_hash;
      await this.provider.waitForTransaction(txHash);
      return { 
        success: true, 
        txHash, 
        message: 'Transaction successful' 
      };
    } catch (error: any) {
      console.error('Transaction error:', error);
      return { 
        success: false, 
        error: error.message || 'Transaction failed' 
      };
    }
  }

  async pauseContract(): Promise<TransactionResult> {
    return this.executeTransaction(() => this.contract.pause());
  }

  async unpauseContract(): Promise<TransactionResult> {
    return this.executeTransaction(() => this.contract.unpause());
  }

  async setPlatformFee(feePercentage: string): Promise<TransactionResult> {
    if (!feePercentage) {
      return { success: false, error: 'Fee percentage is required' };
    }

    try {
      const fee = uint256.bnToUint256(BigInt(feePercentage));
      return this.executeTransaction(() => 
        this.contract.set_platform_fee(fee)
      );
    } catch (error: any) {
      return { success: false, error: 'Invalid fee percentage' };
    }
  }

  async addSupportedToken(tokenAddress: string): Promise<TransactionResult> {
    if (!tokenAddress) {
      return { success: false, error: 'Token address is required' };
    }

    return this.executeTransaction(() => 
      this.contract.set_protocol_token(tokenAddress)
    );
  }

  async removeSupportedToken(tokenAddress: string): Promise<TransactionResult> {
    // Note: Check if your contract has a remove function
    // If not, you might need to implement differently
    return { 
      success: false, 
      error: 'Remove token functionality not implemented in contract' 
    };
  }

  async emergencyCloseMarket(marketId: string, marketType: string): Promise<TransactionResult> {
    if (!marketId || !marketType) {
      return { success: false, error: 'Market ID and type are required' };
    }

    return this.executeTransaction(() => 
      this.contract.emergency_close_market(marketId, marketType)
    );
  }

  async emergencyWithdraw(amount: string, recipient: string): Promise<TransactionResult> {
    if (!amount || !recipient) {
      return { success: false, error: 'Amount and recipient are required' };
    }

    try {
      const amountUint256 = uint256.bnToUint256(BigInt(amount));
      return this.executeTransaction(() => 
        this.contract.emergency_withdraw_tokens(amountUint256, recipient)
      );
    } catch (error: any) {
      return { success: false, error: 'Invalid amount' };
    }
  }
}

export default AdminService;