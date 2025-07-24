// lib/admin/types/admin.types.ts
export interface TransactionResult {
  success: boolean;
  txHash?: string;
  error?: string;
  message?: string;
}

export interface ContractConfig {
  nodeUrl: string;
  contractAddress: string;
  adminPrivateKey: string;
  adminAddress: string;
}