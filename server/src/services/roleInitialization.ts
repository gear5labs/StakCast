import { injectable } from "tsyringe";
import { container } from "tsyringe";
import RoleService from "../api/v1/Role/role.service";
import { UserRole } from "../api/v1/Role/role.entity";
import { User } from "../api/v1/User/user.entity";
import AppDataSource from "../config/DataSource";
import logger from "../config/logger";

@injectable()
export default class RoleInitializationService {
	private roleService: RoleService;
	private userRepository = AppDataSource.getRepository(User);

	constructor() {
		this.roleService = container.resolve(RoleService);
	}

	/**
	 * Initialize default roles for existing users
	 */
	async initializeDefaultRoles(): Promise<void> {
		try {
			logger.info("Initializing default roles for existing users...");

			// Get all users without active roles
			const allUsers = await this.userRepository.find();

			for (const user of allUsers) {
				const existingRoles = await this.roleService.getUserRoles(user.id);

				// If user has no active roles, assign default USER role
				if (existingRoles.length === 0) {
					await this.roleService.assignRole({
						userId: user.id,
						role: UserRole.USER,
						assignedBy: "system-initialization",
					});

					logger.info(`Assigned default USER role to user: ${user.email}`);
				}
			}

			logger.info("Default role initialization completed");
		} catch (error: any) {
			logger.error(`Failed to initialize default roles: ${error.message}`);
			throw error;
		}
	}

	/**
	 * Create initial admin user if none exists
	 */
	async createInitialAdmin(adminEmail: string): Promise<void> {
		try {
			// Check if any admin exists
			const existingAdmins = await this.roleService.getUsersByRole(UserRole.ADMIN);

			if (existingAdmins.length > 0) {
				logger.info("Admin user already exists, skipping creation");
				return;
			}

			// Find user by email
			const adminUser = await this.userRepository.findOne({
				where: { email: adminEmail },
			});

			if (!adminUser) {
				throw new Error(`User with email ${adminEmail} not found`);
			}

			// Assign admin role
			await this.roleService.assignRole({
				userId: adminUser.id,
				role: UserRole.ADMIN,
				assignedBy: "system-initialization",
			});

			logger.info(`Created initial admin user: ${adminEmail}`);
		} catch (error: any) {
			logger.error(`Failed to create initial admin: ${error.message}`);
			throw error;
		}
	}

	/**
	 * Migrate existing user data to include roles
	 */
	async migrateExistingUsers(): Promise<void> {
		try {
			logger.info("Starting user role migration...");

			await this.initializeDefaultRoles();

			// You can add more migration logic here based on your needs
			// For example, promoting certain users based on existing criteria

			logger.info("User role migration completed successfully");
		} catch (error: any) {
			logger.error(`User role migration failed: ${error.message}`);
			throw error;
		}
	}

	/**
	 * Validate role system integrity
	 */
	async validateRoleSystemIntegrity(): Promise<{
		isValid: boolean;
		issues: string[];
		stats: any;
	}> {
		const issues: string[] = [];

		try {
			// Check if all users have at least one active role
			const allUsers = await this.userRepository.find();
			const stats = await this.roleService.getRoleStats();

			// Validate admin exists
			if (stats.adminCount === 0) {
				issues.push("No admin users found in the system");
			}

			// Check for users without roles
			for (const user of allUsers) {
				const userRoles = await this.roleService.getUserRoles(user.id);
				if (userRoles.length === 0) {
					issues.push(`User ${user.email} has no active roles`);
				}
			}

			// Validate role counts match user count
			const totalRoleAssignments = stats.adminCount + stats.moderatorCount + stats.userCount;
			if (totalRoleAssignments < stats.totalUsers) {
				issues.push(
					`Role assignment count mismatch: ${totalRoleAssignments} assignments for ${stats.totalUsers} users`
				);
			}

			return {
				isValid: issues.length === 0,
				issues,
				stats,
			};
		} catch (error: any) {
			issues.push(`Validation error: ${error.message}`);
			return {
				isValid: false,
				issues,
				stats: null,
			};
		}
	}
}
