import { RoleRepository } from './role.repository';
import { RoleType } from './role.entity';

export class RoleService {
  private roleRepository: RoleRepository;

  constructor() {
    this.roleRepository = new RoleRepository();
  }

  async assignRole(userId: string, type: RoleType) {
    try {
      const role = await this.roleRepository.assignRole(userId, type);
      return {
        success: true,
        message: `${type} role assigned successfully`,
        data: role
      };
    } catch (error: any) {
      return {
        success: false,
        message: error.message || 'Failed to assign role'
      };
    }
  }

  async revokeRole(userId: string, type: RoleType) {
    try {
      await this.roleRepository.revokeRole(userId, type);
      return {
        success: true,
        message: `${type} role revoked successfully`
      };
    } catch (error: any) {
      return {
        success: false,
        message: error.message || 'Failed to revoke role'
      };
    }
  }

  async getUserRoles(userId: string) {
    try {
      const roles = await this.roleRepository.getUserRoles(userId);
      return {
        success: true,
        data: roles
      };
    } catch (error: any) {
      return {
        success: false,
        message: error.message || 'Failed to get user roles'
      };
    }
  }

  async hasRole(userId: string, type: RoleType): Promise<boolean> {
    return await this.roleRepository.hasRole(userId, type);
  }

  async getAllUsersWithRole(type: RoleType) {
    try {
      const roles = await this.roleRepository.getAllUsersWithRole(type);
      return {
        success: true,
        data: roles
      };
    } catch (error: any) {
      return {
        success: false,
        message: error.message || 'Failed to get users with role'
      };
    }
  }
}
