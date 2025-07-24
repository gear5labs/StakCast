// lib/admin/routes/admin.routes.ts
import { Router } from 'express';
import AdminController from './admin.controller';

const router = Router();

router.post('/pause', AdminController.pauseContract);
router.post('/unpause', AdminController.unpauseContract);
router.post('/set-fee', AdminController.setPlatformFee);
router.post('/add-token', AdminController.addSupportedToken);
router.post('/remove-token', AdminController.removeSupportedToken);
router.post('/emergency-close-market', AdminController.emergencyCloseMarket);
router.post('/emergency-withdraw', AdminController.emergencyWithdraw);
router.get('/state', AdminController.getAdminState);

export default router;