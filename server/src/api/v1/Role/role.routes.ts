import { Router } from "express";
import { container } from "tsyringe";
import RoleController from "./role.controller";
import { authenticateToken } from "../../../middleware/auth";
import { requireRole, requireMinRole, requireResourceAccess } from "../../../middleware/roleAuth";
import { UserRole } from "./role.types";
import roleManagementRoutes from "./roleManagement.routes";

const router = Router();
const roleController = container.resolve(RoleController);

// All role routes require authentication
router.use(authenticateToken);

// Management routes (admin only)
router.use("/management", roleManagementRoutes);

// Role assignment/revocation (admin only)
router.post("/assign", requireRole(UserRole.ADMIN), roleController.assignRole);
router.delete("/revoke", requireRole(UserRole.ADMIN), roleController.revokeRole);

// Query roles (admin and moderator can see all, users can only see their own)
router.get("/query", requireMinRole(UserRole.MODERATOR), roleController.queryRoles);
router.get("/users/:role", requireMinRole(UserRole.MODERATOR), roleController.getUsersByRole);

// User role checks (users can check their own, admin/moderator can check any)
router.get("/user/:userId", requireResourceAccess(), roleController.getUserRoles);
router.get("/check/:userId/:role", requireResourceAccess(), roleController.checkUserRole);

// Contract event sync (admin only)
router.post("/sync-contract-event", requireRole(UserRole.ADMIN), roleController.syncContractEvent);

// Role statistics (admin and moderator)
router.get("/stats", requireMinRole(UserRole.MODERATOR), roleController.getRoleStats);

export default router;
