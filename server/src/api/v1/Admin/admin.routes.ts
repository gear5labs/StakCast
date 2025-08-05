import { Router } from "express";
import { container } from "tsyringe";
import QueueController from "./queue.controller";
import { authenticateToken } from "../../../middleware/auth";
import AdminController from './admin.controller';

const router = Router();
const queueController = container.resolve(QueueController);

// Queue monitoring endpoints (protected)
router.get("/queue/stats", authenticateToken, queueController.getQueueStats.bind(queueController));
router.post('/pause', AdminController.pauseContract);
router.post('/unpause', AdminController.unpauseContract);
router.post('/set-fee', AdminController.setPlatformFee);
router.post('/add-token', AdminController.addSupportedToken);
router.post('/remove-token', AdminController.removeSupportedToken);
router.post('/emergency-close-market', AdminController.emergencyCloseMarket);
router.post('/emergency-withdraw', AdminController.emergencyWithdraw);
router.get('/state', AdminController.getAdminState);

export default router;
