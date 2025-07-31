import { Request, Response, NextFunction } from "express";
import { container } from "tsyringe";
import RoleService from "../api/v1/Role/role.service.simple";
import { UserRole } from "../api/v1/Role/role.types";

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

/**
 * Middleware to require a specific role
 */
export const requireRole = (requiredRole: UserRole) => {
	return async (req: Request, res: Response, next: NextFunction) => {
		try {
			if (!req.user?.id) {
				return res.status(401).json({ error: "Authentication required" });
			}

			const roleService = container.resolve(RoleService);
			const hasRole = await roleService.hasRole(req.user.id, requiredRole);

			if (!hasRole) {
				return res.status(403).json({
					error: `${requiredRole} role required`,
				});
			}

			// Add role to request for future use
			const userHighestRole = await roleService.getUserHighestRole(req.user.id);
			req.user.role = userHighestRole;

			next();
		} catch (error) {
			return res.status(500).json({
				error: "Failed to verify role",
			});
		}
	};
};

/**
 * Middleware to require minimum role level
 * Role hierarchy: admin > moderator > user
 */
export const requireMinRole = (minRole: UserRole) => {
	return async (req: Request, res: Response, next: NextFunction) => {
		try {
			if (!req.user?.id) {
				return res.status(401).json({ error: "Authentication required" });
			}

			const roleService = container.resolve(RoleService);
			const userHighestRole = await roleService.getUserHighestRole(req.user.id);

			const roleHierarchy = {
				[UserRole.USER]: 0,
				[UserRole.MODERATOR]: 1,
				[UserRole.ADMIN]: 2,
			};

			const userRoleLevel = roleHierarchy[userHighestRole];
			const minRoleLevel = roleHierarchy[minRole];

			if (userRoleLevel < minRoleLevel) {
				return res.status(403).json({
					error: `Minimum ${minRole} role required`,
				});
			}

			// Add role to request for future use
			req.user.role = userHighestRole;

			next();
		} catch (error) {
			return res.status(500).json({
				error: "Failed to verify role",
			});
		}
	};
};

/**
 * Middleware to check if user can access resource
 * Users can access their own resources, admin/moderator can access any
 */
export const requireResourceAccess = (resourceUserIdParam: string = "userId") => {
	return async (req: Request, res: Response, next: NextFunction) => {
		try {
			if (!req.user?.id) {
				return res.status(401).json({ error: "Authentication required" });
			}

			const resourceUserId = req.params[resourceUserIdParam] || req.body[resourceUserIdParam];
			const currentUserId = req.user.id;

			// If accessing own resource, allow
			if (resourceUserId === currentUserId) {
				return next();
			}

			// Check if user has admin or moderator role
			const roleService = container.resolve(RoleService);
			const userHighestRole = await roleService.getUserHighestRole(currentUserId);

			if (userHighestRole === UserRole.ADMIN || userHighestRole === UserRole.MODERATOR) {
				req.user.role = userHighestRole;
				return next();
			}

			return res.status(403).json({
				error: "Access denied to this resource",
			});
		} catch (error) {
			return res.status(500).json({
				error: "Failed to verify resource access",
			});
		}
	};
};

/**
 * Middleware to add user role to request without enforcing access control
 */
export const addUserRole = async (req: Request, res: Response, next: NextFunction) => {
	try {
		if (req.user?.id) {
			const roleService = container.resolve(RoleService);
			const userHighestRole = await roleService.getUserHighestRole(req.user.id);
			req.user.role = userHighestRole;
		}
		next();
	} catch (error) {
		// Don't fail the request if role lookup fails
		next();
	}
};
