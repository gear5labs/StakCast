import { Router } from "express";
import { container } from "tsyringe";
import RoleManagementController from "./roleManagement.controller";
import { authenticateToken } from "../../../middleware/auth";
import { requireRole } from "../../../middleware/roleAuth";
import { UserRole } from "./role.types";

const router = Router();
const roleManagementController = container.resolve(RoleManagementController);

// All management routes require authentication and admin role
router.use(authenticateToken);
router.use(requireRole(UserRole.ADMIN));

// Role initialization and migration
router.post("/init-defaults", roleManagementController.initializeDefaultRoles);
router.post("/create-admin", roleManagementController.createInitialAdmin);
router.post("/migrate", roleManagementController.migrateExistingUsers);
router.get("/validate", roleManagementController.validateRoleSystem);

// Contract event listener management
router.post("/start-listener", roleManagementController.startEventListener);
router.post("/stop-listener", roleManagementController.stopEventListener);
router.get("/listener-status", roleManagementController.getEventListenerStatus);
router.post("/sync-missed-events", roleManagementController.syncMissedEvents);

export default router;
