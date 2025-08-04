export interface DeployResult {
	success: boolean;
	userAddress?: string;
	transactionHash?: string;
	error?: string;
}

export type Token = "STRK" | "ETH";
