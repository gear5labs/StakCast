import { Request, Response } from "express";
import { container } from "tsyringe";
import RoleService from "./role.service.simple";
import { UserRole, IRoleAssignmentRequest } from "./role.types";

// Extend Request interface to include user
declare global {
	namespace Express {
		interface Request {
			user?: {
				id: string;
				role?: UserRole;
			};
		}
	}
}

export default class RoleController {
	private roleService: RoleService;

	constructor() {
		this.roleService = container.resolve(RoleService);
	}

	/**
	 * Assign role to user
	 * POST /api/v1/roles/assign
	 */
	assignRole = async (req: Request, res: Response): Promise<void> => {
		try {
			const { userId, role, contractAddress, transactionHash } = req.body;
			const assignedBy = req.user?.id;

			if (!assignedBy) {
				res.status(401).json({ error: "Unauthorized" });
				return;
			}

			if (!userId || !role) {
				res.status(400).json({
					error: "Missing required fields: userId and role",
				});
				return;
			}

			if (!Object.values(UserRole).includes(role)) {
				res.status(400).json({
					error: "Invalid role. Must be one of: admin, moderator, user",
				});
				return;
			}

			const request: IRoleAssignmentRequest = {
				userId,
				role,
				assignedBy,
				contractAddress,
				transactionHash,
			};

			const roleAssignment = await this.roleService.assignRole(request);

			res.status(201).json({
				message: "Role assigned successfully",
				data: roleAssignment,
			});
		} catch (error: any) {
			res.status(400).json({
				error: error.message || "Failed to assign role",
			});
		}
	};

	/**
	 * Revoke role from user
	 * DELETE /api/v1/roles/revoke
	 */
	revokeRole = async (req: Request, res: Response): Promise<void> => {
		try {
			const { userId, role } = req.body;
			const revokedBy = req.user?.id;

			if (!revokedBy) {
				res.status(401).json({ error: "Unauthorized" });
				return;
			}

			if (!userId || !role) {
				res.status(400).json({
					error: "Missing required fields: userId and role",
				});
				return;
			}

			if (!Object.values(UserRole).includes(role)) {
				res.status(400).json({
					error: "Invalid role. Must be one of: admin, moderator, user",
				});
				return;
			}

			const success = await this.roleService.revokeRole(userId, role, revokedBy);

			res.status(200).json({
				message: "Role revoked successfully",
				data: { success },
			});
		} catch (error: any) {
			res.status(400).json({
				error: error.message || "Failed to revoke role",
			});
		}
	};

	/**
	 * Get user roles
	 * GET /api/v1/roles/user/:userId
	 */
	getUserRoles = async (req: Request, res: Response): Promise<void> => {
		try {
			const { userId } = req.params;

			if (!userId) {
				res.status(400).json({ error: "User ID is required" });
				return;
			}

			const roles = await this.roleService.getUserRoles(userId);
			const highestRole = await this.roleService.getUserHighestRole(userId);

			res.status(200).json({
				message: "User roles retrieved successfully",
				data: {
					roles,
					highestRole,
				},
			});
		} catch (error: any) {
			res.status(500).json({
				error: error.message || "Failed to get user roles",
			});
		}
	};

	/**
	 * Check if user has specific role
	 * GET /api/v1/roles/check/:userId/:role
	 */
	checkUserRole = async (req: Request, res: Response): Promise<void> => {
		try {
			const { userId, role } = req.params;

			if (!userId || !role) {
				res.status(400).json({ error: "User ID and role are required" });
				return;
			}

			if (!Object.values(UserRole).includes(role as UserRole)) {
				res.status(400).json({
					error: "Invalid role. Must be one of: admin, moderator, user",
				});
				return;
			}

			const hasRole = await this.roleService.hasRole(userId, role as UserRole);

			res.status(200).json({
				message: "Role check completed",
				data: { hasRole },
			});
		} catch (error: any) {
			res.status(500).json({
				error: error.message || "Failed to check user role",
			});
		}
	};

	/**
	 * Query roles with filters
	 * GET /api/v1/roles/query
	 */
	queryRoles = async (req: Request, res: Response): Promise<void> => {
		try {
			const { userId, role, isActive, contractAddress } = req.query;

			const filters: any = {};
			if (userId) filters.userId = userId as string;
			if (role) filters.role = role as UserRole;
			if (isActive !== undefined) filters.isActive = isActive === "true";
			if (contractAddress) filters.contractAddress = contractAddress as string;

			const roles = await this.roleService.queryRoles(filters);

			res.status(200).json({
				message: "Roles retrieved successfully",
				data: roles,
			});
		} catch (error: any) {
			res.status(500).json({
				error: error.message || "Failed to query roles",
			});
		}
	};

	/**
	 * Get users by role
	 * GET /api/v1/roles/users/:role
	 */
	getUsersByRole = async (req: Request, res: Response): Promise<void> => {
		try {
			const { role } = req.params;

			if (!Object.values(UserRole).includes(role as UserRole)) {
				res.status(400).json({
					error: "Invalid role. Must be one of: admin, moderator, user",
				});
				return;
			}

			const users = await this.roleService.getUsersByRole(role as UserRole);

			res.status(200).json({
				message: "Users retrieved successfully",
				data: users,
			});
		} catch (error: any) {
			res.status(500).json({
				error: error.message || "Failed to get users by role",
			});
		}
	};

	/**
	 * Sync role with contract event
	 * POST /api/v1/roles/sync-contract-event
	 */
	syncContractEvent = async (req: Request, res: Response): Promise<void> => {
		try {
			const { eventType, moderatorAddress, transactionHash, contractAddress } = req.body;

			if (!eventType || !moderatorAddress || !transactionHash || !contractAddress) {
				res.status(400).json({
					error: "Missing required fields: eventType, moderatorAddress, transactionHash, contractAddress",
				});
				return;
			}

			if (!["ModeratorAdded", "ModeratorRemoved"].includes(eventType)) {
				res.status(400).json({
					error: "Invalid event type. Must be ModeratorAdded or ModeratorRemoved",
				});
				return;
			}

			const result = await this.roleService.syncWithContractEvent(
				eventType,
				moderatorAddress,
				transactionHash,
				contractAddress
			);

			res.status(200).json({
				message: "Contract event synced successfully",
				data: result,
			});
		} catch (error: any) {
			res.status(500).json({
				error: error.message || "Failed to sync contract event",
			});
		}
	};

	/**
	 * Get role statistics
	 * GET /api/v1/roles/stats
	 */
	getRoleStats = async (req: Request, res: Response): Promise<void> => {
		try {
			const stats = await this.roleService.getRoleStats();

			res.status(200).json({
				message: "Role statistics retrieved successfully",
				data: stats,
			});
		} catch (error: any) {
			res.status(500).json({
				error: error.message || "Failed to get role statistics",
			});
		}
	};
}
