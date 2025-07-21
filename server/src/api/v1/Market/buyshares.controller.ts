import { Request, Response } from 'express';
import { buySharesService } from './buyshares.service';

export const buyShares = async (req: Request, res: Response) => {
  try {
    const { userId, marketId, amount } = req.body;
    const result = await buySharesService(userId, marketId, amount);
    res.status(200).json({ success: true, data: result });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
};
