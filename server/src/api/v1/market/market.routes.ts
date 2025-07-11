import { Router } from 'express';
import { MarketController } from './market.controller';
import { container } from 'tsyringe';

const router = Router();
const marketController = container.resolve(MarketController);

router.get('/markets', marketController.getMarkets.bind(marketController));
router.get('/markets/:id', marketController.getMarketById.bind(marketController));
router.post('/markets', marketController.createMarket.bind(marketController));

export default router;
