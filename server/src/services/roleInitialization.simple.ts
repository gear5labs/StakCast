import { injectable } from "tsyringe";
import { container } from "tsyringe";
import RoleService from "../api/v1/Role/role.service.simple";
import { UserRole } from "../api/v1/Role/role.types";
import logger from "../config/logger";

@injectable()
export default class RoleInitializationService {
	private roleService: RoleService;

	constructor() {
		this.roleService = container.resolve(RoleService);
	}

	/**
	 * Initialize default roles for existing users
	 */
	async initializeDefaultRoles(): Promise<void> {
		try {
			logger.info("Initializing default roles for existing users...");

			// For demo purposes, create some default users
			const defaultUsers = [
				{ id: "user1", email: "user1@example.com" },
				{ id: "user2", email: "user2@example.com" },
				{ id: "user3", email: "user3@example.com" },
			];

			for (const user of defaultUsers) {
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

			// For demo, create admin with email as ID
			const adminUserId = `admin_${adminEmail.replace("@", "_").replace(".", "_")}`;

			// Assign admin role
			await this.roleService.assignRole({
				userId: adminUserId,
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
			const stats = await this.roleService.getRoleStats();

			// Validate admin exists
			if (stats.adminCount === 0) {
				issues.push("No admin users found in the system");
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
