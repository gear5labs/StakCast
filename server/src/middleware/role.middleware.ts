import { Request, Response, NextFunction } from 'express';
import { RoleService } from '../api/v1/Role/role.service';
import { RoleType } from '../api/v1/Role/role.entity';

export const requireRole = (requiredRole: RoleType) => {
  return async (req: Request, res: Response, next: NextFunction) => {
    try {
      // Check if user is authenticated
      if (!req.user?.id) {
        return res.status(401).json({
          success: false,
          message: 'Authentication required'
        });
      }

      const roleService = new RoleService();

      // Check if user has the required role
      const hasRole = await roleService.hasRole(req.user.id, requiredRole);

      if (!hasRole) {
        // Special case: if requiring MODERATOR, allow ADMIN as well
        if (requiredRole === RoleType.MODERATOR) {
          const isAdmin = await roleService.hasRole(req.user.id, RoleType.ADMIN);
          if (isAdmin) {
            return next();
          }
        }

        return res.status(403).json({
          success: false,
          message: `Access denied. Required role: ${requiredRole}`
        });
      }

      next();
    } catch (error: any) {
      return res.status(500).json({
        success: false,
        message: 'Role check failed',
        error: error.message
      });
    }
  };
};

export const requireAnyRole = (roles: RoleType[]) => {
  return async (req: Request, res: Response, next: NextFunction) => {
    try {
      // Check if user is authenticated
      if (!req.user?.id) {
        return res.status(401).json({
          success: false,
          message: 'Authentication required'
        });
      }

      const roleService = new RoleService();

      // Check if user has any of the required roles
      for (const role of roles) {
        const hasRole = await roleService.hasRole(req.user.id, role);
        if (hasRole) {
          return next();
        }
      }

      return res.status(403).json({
        success: false,
        message: `Access denied. Required roles: ${roles.join(', ')}`
      });
    } catch (error: any) {
      return res.status(500).json({
        success: false,
        message: 'Role check failed',
        error: error.message
      });
    }
  };
};
