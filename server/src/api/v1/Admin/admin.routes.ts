import { Router } from "express";
import { container } from "tsyringe";
import QueueController from "./queue.controller";
import { authenticateToken } from "../../../middleware/auth";
import AdminController from './admin.controller';
const router = Router();
const queueController = container.resolve(QueueController);
const adminController=container.resolve(AdminController)
// Queue monitoring endpoints (protected)
router.get("/queue/stats", authenticateToken, queueController.getQueueStats.bind(queueController));
router.post('/pause', adminController.pauseContract);
router.post('/unpause', adminController.unpauseContract);
router.post('/set-fee', adminController.setPlatformFee);
router.post('/add-token', adminController.addSupportedToken);
router.post('/remove-token', adminController.removeSupportedToken);
router.post('/emergency-close-market', adminController.emergencyCloseMarket);
router.post('/emergency-withdraw', adminController.emergencyWithdraw);
router.get('/state', adminController.getAdminState);

export default router;
