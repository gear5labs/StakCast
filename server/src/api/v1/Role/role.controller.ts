import { Request, Response } from 'express';
import { RoleService } from './role.service';
import { RoleType } from './role.entity';
import HttpStatusCodes from '../../../constants/HttpStatusCodes';

export class RoleController {
  private roleService: RoleService;

  constructor() {
    this.roleService = new RoleService();
  }

  assignRole = async (req: Request, res: Response) => {
    try {
      const { userId, type } = req.body;

      if (!userId || !type) {
        return res.status(HttpStatusCodes.BAD_REQUEST).json({
          success: false,
          message: 'userId and type are required'
        });
      }

      if (!Object.values(RoleType).includes(type)) {
        return res.status(HttpStatusCodes.BAD_REQUEST).json({
          success: false,
          message: 'Invalid role type'
        });
      }

      const result = await this.roleService.assignRole(userId, type);

      if (result.success) {
        return res.status(HttpStatusCodes.CREATED).json(result);
      } else {
        return res.status(HttpStatusCodes.BAD_REQUEST).json(result);
      }
    } catch (error: any) {
      return res.status(HttpStatusCodes.INTERNAL_SERVER_ERROR).json({
        success: false,
        message: error.message || 'Internal server error'
      });
    }
  };

  revokeRole = async (req: Request, res: Response) => {
    try {
      const { userId, type } = req.body;

      if (!userId || !type) {
        return res.status(HttpStatusCodes.BAD_REQUEST).json({
          success: false,
          message: 'userId and type are required'
        });
      }

      if (!Object.values(RoleType).includes(type)) {
        return res.status(HttpStatusCodes.BAD_REQUEST).json({
          success: false,
          message: 'Invalid role type'
        });
      }

      const result = await this.roleService.revokeRole(userId, type);

      if (result.success) {
        return res.status(HttpStatusCodes.OK).json(result);
      } else {
        return res.status(HttpStatusCodes.BAD_REQUEST).json(result);
      }
    } catch (error: any) {
      return res.status(HttpStatusCodes.INTERNAL_SERVER_ERROR).json({
        success: false,
        message: error.message || 'Internal server error'
      });
    }
  };

  getUserRoles = async (req: Request, res: Response) => {
    try {
      const { userId } = req.params;

      if (!userId) {
        return res.status(HttpStatusCodes.BAD_REQUEST).json({
          success: false,
          message: 'userId is required'
        });
      }

      const result = await this.roleService.getUserRoles(userId);

      if (result.success) {
        return res.status(HttpStatusCodes.OK).json(result);
      } else {
        return res.status(HttpStatusCodes.BAD_REQUEST).json(result);
      }
    } catch (error: any) {
      return res.status(HttpStatusCodes.INTERNAL_SERVER_ERROR).json({
        success: false,
        message: error.message || 'Internal server error'
      });
    }
  };

  getAllUsersWithRole = async (req: Request, res: Response) => {
    try {
      const { type } = req.params;

      if (!type || !Object.values(RoleType).includes(type as RoleType)) {
        return res.status(HttpStatusCodes.BAD_REQUEST).json({
          success: false,
          message: 'Valid role type is required'
        });
      }

      const result = await this.roleService.getAllUsersWithRole(type as RoleType);

      if (result.success) {
        return res.status(HttpStatusCodes.OK).json(result);
      } else {
        return res.status(HttpStatusCodes.BAD_REQUEST).json(result);
      }
    } catch (error: any) {
      return res.status(HttpStatusCodes.INTERNAL_SERVER_ERROR).json({
        success: false,
        message: error.message || 'Internal server error'
      });
    }
  };
}
