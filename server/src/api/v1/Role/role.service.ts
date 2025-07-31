import { injectable } from "tsyringe";
import { Repository } from "typeorm";
import AppDataSource from "../../../config/DataSource";
import { UserRoleEntity, UserRole } from "./role.entity";
import { User } from "../User/user.entity";

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

@injectable()
export default class RoleService {
	private roleRepository: Repository<UserRoleEntity>;
	private userRepository: Repository<User>;

	constructor() {
		this.roleRepository = AppDataSource.getRepository(UserRoleEntity);
		this.userRepository = AppDataSource.getRepository(User);
	}

	/**
	 * Assign a role to a user
	 */
	async assignRole(request: IRoleAssignmentRequest): Promise<UserRoleEntity> {
		// Check if user exists
		const user = await this.userRepository.findOne({ where: { id: request.userId } });
		if (!user) {
			throw new Error("User not found");
		}

		// Check if user already has this role
		const existingRole = await this.roleRepository.findOne({
			where: {
				userId: request.userId,
				role: request.role,
				isActive: true,
			},
		});

		if (existingRole) {
			throw new Error(`User already has ${request.role} role`);
		}

		// Deactivate existing roles if assigning admin or moderator
		if (request.role === UserRole.ADMIN || request.role === UserRole.MODERATOR) {
			await this.roleRepository.update({ userId: request.userId, isActive: true }, { isActive: false });
		}

		// Create new role assignment
		const roleAssignment = this.roleRepository.create({
			userId: request.userId,
			role: request.role,
			assignedBy: request.assignedBy,
			contractAddress: request.contractAddress,
			transactionHash: request.transactionHash,
			isActive: true,
		});

		return await this.roleRepository.save(roleAssignment);
	}

	/**
	 * Revoke a role from a user
	 */
	async revokeRole(userId: string, role: UserRole, revokedBy: string): Promise<boolean> {
		const roleAssignment = await this.roleRepository.findOne({
			where: {
				userId,
				role,
				isActive: true,
			},
		});

		if (!roleAssignment) {
			throw new Error(`User does not have ${role} role`);
		}

		// Deactivate the role
		roleAssignment.isActive = false;
		roleAssignment.updatedAt = new Date();
		await this.roleRepository.save(roleAssignment);

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
	async getUserRoles(userId: string): Promise<UserRoleEntity[]> {
		return await this.roleRepository.find({
			where: {
				userId,
				isActive: true,
			},
			relations: ["user"],
			order: { createdAt: "DESC" },
		});
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
		const roleAssignment = await this.roleRepository.findOne({
			where: {
				userId,
				role,
				isActive: true,
			},
		});
		return !!roleAssignment;
	}

	/**
	 * Query roles with filters
	 */
	async queryRoles(filters: IRoleQueryFilters = {}): Promise<UserRoleEntity[]> {
		const queryBuilder = this.roleRepository.createQueryBuilder("role").leftJoinAndSelect("role.user", "user");

		if (filters.userId) {
			queryBuilder.andWhere("role.userId = :userId", { userId: filters.userId });
		}

		if (filters.role) {
			queryBuilder.andWhere("role.role = :role", { role: filters.role });
		}

		if (filters.isActive !== undefined) {
			queryBuilder.andWhere("role.isActive = :isActive", { isActive: filters.isActive });
		}

		if (filters.contractAddress) {
			queryBuilder.andWhere("role.contractAddress = :contractAddress", {
				contractAddress: filters.contractAddress,
			});
		}

		return await queryBuilder.orderBy("role.createdAt", "DESC").getMany();
	}

	/**
	 * Get all users with specific role
	 */
	async getUsersByRole(role: UserRole): Promise<UserRoleEntity[]> {
		return await this.roleRepository.find({
			where: {
				role,
				isActive: true,
			},
			relations: ["user"],
			order: { createdAt: "DESC" },
		});
	}

	/**
	 * Sync role with contract event (for ModeratorAdded/ModeratorRemoved events)
	 */
	async syncWithContractEvent(
		eventType: "ModeratorAdded" | "ModeratorRemoved",
		moderatorAddress: string,
		transactionHash: string,
		contractAddress: string
	): Promise<UserRoleEntity | boolean> {
		// Find user by wallet address (assuming we have this field)
		// For now, we'll use email as identifier since the current User entity doesn't have wallet address
		// In a real implementation, you'd have a wallet address field in User entity

		if (eventType === "ModeratorAdded") {
			// For demo purposes, we'll create a placeholder user if not found
			// In real implementation, you'd have proper wallet-to-user mapping
			const roleAssignment = await this.assignRole({
				userId: "system-generated", // This should be resolved from wallet address
				role: UserRole.MODERATOR,
				assignedBy: "contract-event",
				contractAddress,
				transactionHash,
			});
			return roleAssignment;
		} else if (eventType === "ModeratorRemoved") {
			// Find and revoke moderator role
			const roleAssignments = await this.roleRepository.find({
				where: {
					role: UserRole.MODERATOR,
					contractAddress,
					isActive: true,
				},
			});

			for (const assignment of roleAssignments) {
				assignment.isActive = false;
				assignment.updatedAt = new Date();
				await this.roleRepository.save(assignment);
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
		const [totalUsers, adminCount, moderatorCount, userCount] = await Promise.all([
			this.userRepository.count(),
			this.roleRepository.count({ where: { role: UserRole.ADMIN, isActive: true } }),
			this.roleRepository.count({ where: { role: UserRole.MODERATOR, isActive: true } }),
			this.roleRepository.count({ where: { role: UserRole.USER, isActive: true } }),
		]);

		return {
			totalUsers,
			adminCount,
			moderatorCount,
			userCount,
		};
	}
}
