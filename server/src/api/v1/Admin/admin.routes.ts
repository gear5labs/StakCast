import { Router } from "express";
import { container } from "tsyringe";
import AdminController from "./admin.controller";
import { authenticateToken, requireAdmin } from "../../../middleware/auth";

const router = Router();
const adminController = container.resolve(AdminController);

// Contract control endpoints
router.post("/pause", authenticateToken, requireAdmin, adminController.pauseContract.bind(adminController));
router.post("/unpause", authenticateToken, requireAdmin, adminController.unpauseContract.bind(adminController));
router.post("/set-fee", authenticateToken, requireAdmin, adminController.setFee.bind(adminController));
router.post("/add-token", authenticateToken, requireAdmin, adminController.addSupportedToken.bind(adminController));
router.post(
	"/remove-token",
	authenticateToken,
	requireAdmin,
	adminController.removeSupportedToken.bind(adminController)
);

// Emergency endpoints
router.post("/close-market", authenticateToken, requireAdmin, adminController.closeMarket.bind(adminController));
router.post(
	"/emergency-withdraw",
	authenticateToken,
	requireAdmin,
	adminController.emergencyWithdraw.bind(adminController)
);

export default router;
