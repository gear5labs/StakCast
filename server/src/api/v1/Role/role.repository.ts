import { Repository } from 'typeorm';
import { Role, RoleType } from './role.entity';
import AppDataSource from '../../../config/DataSource';

export class RoleRepository {
  private repository: Repository<Role>;

  constructor() {
    this.repository = AppDataSource.getRepository(Role);
  }

  async assignRole(userId: string, type: RoleType): Promise<Role> {
    // Check if role already exists
    const existingRole = await this.repository.findOne({
      where: { userId, type }
    });

    if (existingRole) {
      throw new Error(`User already has ${type} role`);
    }

    const role = this.repository.create({ userId, type });
    return await this.repository.save(role);
  }

  async revokeRole(userId: string, type: RoleType): Promise<void> {
    const result = await this.repository.delete({ userId, type });
    if (result.affected === 0) {
      throw new Error(`User does not have ${type} role`);
    }
  }

  async getUserRoles(userId: string): Promise<Role[]> {
    return await this.repository.find({
      where: { userId },
      relations: ['user']
    });
  }

  async hasRole(userId: string, type: RoleType): Promise<boolean> {
    const role = await this.repository.findOne({
      where: { userId, type }
    });
    return !!role;
  }

  async getAllUsersWithRole(type: RoleType): Promise<Role[]> {
    return await this.repository.find({
      where: { type },
      relations: ['user']
    });
  }
}
