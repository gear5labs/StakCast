export enum UserRole {
	ADMIN = "admin",
	MODERATOR = "moderator",
	USER = "user",
}

export interface IRoleAssignmentRequest {
	userId: string;
	role: UserRole;
	assignedBy: string;
	contractAddress?: string;
	transactionHash?: string;
}

export interface IRoleQueryFilters {
	userId?: string;
	role?: UserRole;
	isActive?: boolean;
	contractAddress?: string;
}
