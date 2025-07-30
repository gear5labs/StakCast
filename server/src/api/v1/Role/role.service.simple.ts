import { injectable } from "tsyringe";
import { UserRole } from "./role.types";

interface UserRoleData {
	id: string;
	userId: string;
	role: UserRole;
	assignedBy: string;
	contractAddress?: string;
	transactionHash?: string;
	isActive: boolean;
	createdAt: Date;
	updatedAt: Date;
}

@injectable()
export default class RoleService {
	private roles: Map<string, UserRoleData[]> = new Map();

	/**
	 * Assign a role to a user
	 */
	async assignRole(request: {
		userId: string;
		role: UserRole;
		assignedBy: string;
		contractAddress?: string;
		transactionHash?: string;
	}): Promise<UserRoleData> {
		const existingRoles = this.roles.get(request.userId) || [];

		// Check if user already has this role
		const hasRole = existingRoles.some(r => r.role === request.role && r.isActive);
		if (hasRole) {
			throw new Error(`User already has ${request.role} role`);
		}

		// Deactivate existing roles if assigning admin or moderator
		if (request.role === UserRole.ADMIN || request.role === UserRole.MODERATOR) {
			existingRoles.forEach(r => (r.isActive = false));
		}

		const roleData: UserRoleData = {
			id: `role_${Date.now()}_${Math.random().toString(36).substring(7)}`,
			userId: request.userId,
			role: request.role,
			assignedBy: request.assignedBy,
			contractAddress: request.contractAddress,
			transactionHash: request.transactionHash,
			isActive: true,
			createdAt: new Date(),
			updatedAt: new Date(),
		};

		existingRoles.push(roleData);
		this.roles.set(request.userId, existingRoles);

		return roleData;
	}

	/**
	 * Revoke a role from a user
	 */
	async revokeRole(userId: string, role: UserRole, revokedBy: string): Promise<boolean> {
		const userRoles = this.roles.get(userId) || [];
		const roleToRevoke = userRoles.find(r => r.role === role && r.isActive);

		if (!roleToRevoke) {
			throw new Error(`User does not have ${role} role`);
		}

		roleToRevoke.isActive = false;
		roleToRevoke.updatedAt = new Date();

		// If revoking admin/moderator, assign default user role
		if (role === UserRole.ADMIN || role === UserRole.MODERATOR) {
			await this.assignRole({
				userId,
				role: UserRole.USER,
				assignedBy: revokedBy,
			});
		}

		return true;
	}

	/**
	 * Get user's active roles
	 */
	async getUserRoles(userId: string): Promise<UserRoleData[]> {
		const userRoles = this.roles.get(userId) || [];
		return userRoles.filter(r => r.isActive);
	}

	/**
	 * Get user's highest priority role
	 */
	async getUserHighestRole(userId: string): Promise<UserRole> {
		const roles = await this.getUserRoles(userId);

		if (roles.some(r => r.role === UserRole.ADMIN)) {
			return UserRole.ADMIN;
		}
		if (roles.some(r => r.role === UserRole.MODERATOR)) {
			return UserRole.MODERATOR;
		}
		return UserRole.USER;
	}

	/**
	 * Check if user has specific role
	 */
	async hasRole(userId: string, role: UserRole): Promise<boolean> {
		const userRoles = this.roles.get(userId) || [];
		return userRoles.some(r => r.role === role && r.isActive);
	}

	/**
	 * Query roles with filters
	 */
	async queryRoles(
		filters: {
			userId?: string;
			role?: UserRole;
			isActive?: boolean;
			contractAddress?: string;
		} = {}
	): Promise<UserRoleData[]> {
		let allRoles: UserRoleData[] = [];

		// Convert Map values to array properly
		const allUserRoles = Array.from(this.roles.values());
		for (const userRoles of allUserRoles) {
			allRoles = allRoles.concat(userRoles);
		}

		return allRoles.filter(role => {
			if (filters.userId && role.userId !== filters.userId) return false;
			if (filters.role && role.role !== filters.role) return false;
			if (filters.isActive !== undefined && role.isActive !== filters.isActive) return false;
			if (filters.contractAddress && role.contractAddress !== filters.contractAddress) return false;
			return true;
		});
	}

	/**
	 * Get all users with specific role
	 */
	async getUsersByRole(role: UserRole): Promise<UserRoleData[]> {
		return this.queryRoles({ role, isActive: true });
	}

	/**
	 * Sync role with contract event
	 */
	async syncWithContractEvent(
		eventType: "ModeratorAdded" | "ModeratorRemoved",
		moderatorAddress: string,
		transactionHash: string,
		contractAddress: string
	): Promise<UserRoleData | boolean> {
		if (eventType === "ModeratorAdded") {
			const roleAssignment = await this.assignRole({
				userId: `contract_${moderatorAddress}`,
				role: UserRole.MODERATOR,
				assignedBy: "contract-event",
				contractAddress,
				transactionHash,
			});
			return roleAssignment;
		} else if (eventType === "ModeratorRemoved") {
			const roleAssignments = await this.queryRoles({
				role: UserRole.MODERATOR,
				contractAddress,
				isActive: true,
			});

			for (const assignment of roleAssignments) {
				assignment.isActive = false;
				assignment.updatedAt = new Date();
			}
			return true;
		}

		return false;
	}

	/**
	 * Get role statistics
	 */
	async getRoleStats(): Promise<{
		totalUsers: number;
		adminCount: number;
		moderatorCount: number;
		userCount: number;
	}> {
		const allActiveRoles = await this.queryRoles({ isActive: true });
		const uniqueUsers = new Set(allActiveRoles.map(r => r.userId));

		return {
			totalUsers: uniqueUsers.size,
			adminCount: allActiveRoles.filter(r => r.role === UserRole.ADMIN).length,
			moderatorCount: allActiveRoles.filter(r => r.role === UserRole.MODERATOR).length,
			userCount: allActiveRoles.filter(r => r.role === UserRole.USER).length,
		};
	}
}
