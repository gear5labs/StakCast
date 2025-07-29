import { Router } from 'express';
import { container } from 'tsyringe';
import AdminController from './admin.controller';

const router = Router();
const adminController = container.resolve(AdminController);

router.post('/pause', adminController.pauseContract.bind(adminController));
router.post('/unpause', adminController.unpauseContract.bind(adminController));
router.post('/set-fee', adminController.setPlatformFee.bind(adminController));
router.post('/add-token', adminController.addSupportedToken.bind(adminController));
router.post('/remove-token', adminController.removeSupportedToken.bind(adminController));
router.post('/emergency-close-market', adminController.emergencyCloseMarket.bind(adminController));
router.post('/emergency-withdraw', adminController.emergencyWithdraw.bind(adminController));
router.get('/state', adminController.getAdminState.bind(adminController));

export default router;