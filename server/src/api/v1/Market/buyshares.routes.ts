import { Router } from 'express';
import { buyShares } from './buyshares.controller';

const router = Router();

// POST /api/v1/market/buyshares
router.post('/buyshares', buyShares);

export default router;
