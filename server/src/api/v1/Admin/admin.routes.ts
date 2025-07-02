import { Router } from "express";
import { container } from "tsyringe";
import AdminController from "./admin.controller";
import { authenticateToken, requireAdmin } from "../../../middleware/auth";

const router = Router();
const adminController = container.resolve(AdminController);

// Contract control endpoints
router.post("/pause", authenticateToken, requireAdmin, adminController.pauseContract);
router.post("/unpause", authenticateToken, requireAdmin, adminController.unpauseContract);
router.post("/set-fee", authenticateToken, requireAdmin, adminController.setFee);
router.post("/add-token", authenticateToken, requireAdmin, adminController.addSupportedToken);
router.post("/remove-token", authenticateToken, requireAdmin, adminController.removeSupportedToken);

// Emergency endpoints
router.post("/close-market", authenticateToken, requireAdmin, adminController.closeMarket);
router.post("/emergency-withdraw", authenticateToken, requireAdmin, adminController.emergencyWithdraw);

export default router;
