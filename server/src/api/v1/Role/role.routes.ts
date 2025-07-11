import { Router } from 'express';
import { RoleController } from './role.controller';
import { authenticateToken } from '../../../middleware/auth';
import { requireRole } from '../../../middleware/role.middleware';
import { RoleType } from './role.entity';

const router = Router();
const roleController = new RoleController();

// Protected routes - require authentication
router.use(authenticateToken);

// Assign role - only admins can assign roles
router.post('/assign', requireRole(RoleType.ADMIN), roleController.assignRole);

// Revoke role - only admins can revoke roles
router.post('/revoke', requireRole(RoleType.ADMIN), roleController.revokeRole);

// Get user roles - authenticated users can view roles
router.get('/user/:userId', roleController.getUserRoles);

// Get all users with specific role - only admins and moderators
router.get('/type/:type', requireRole(RoleType.MODERATOR), roleController.getAllUsersWithRole);

export default router;
