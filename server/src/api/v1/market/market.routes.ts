import { Router } from 'express';
import { MarketController } from './market.controller';

const router = Router();
const marketController = new MarketController();

router.get('/markets', marketController.getMarkets);
router.get('/markets/:id', marketController.getMarketById);
router.post('/markets', marketController.createMarket);

export default router;
