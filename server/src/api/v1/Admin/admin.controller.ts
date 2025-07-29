import { Request, Response } from 'express';
import { injectable, inject } from 'tsyringe';
import AdminService from './admin.service';
import AdminStateService from './adminState.service';

@injectable()
class AdminController {
  constructor(
    @inject(AdminService) private service: AdminService,
    @inject(AdminStateService) private stateService: AdminStateService
  ) {}

  async pauseContract(req: Request, res: Response) {
    try {
      const result = await this.service.pauseContract();
      res.status(result.success ? 200 : 400).json(result);
    } catch (error) {
      const err = error as Error;
      res.status(500).json({ success: false, error: err.message });
    }
  }

  async unpauseContract(req: Request, res: Response) {
    try {
      const result = await this.service.unpauseContract();
      res.status(result.success ? 200 : 400).json(result);
    } catch (error) {
      const err = error as Error;
      res.status(500).json({ success: false, error: err.message });
    }
  }

  async setPlatformFee(req: Request, res: Response) {
    try {
      const { feePercentage } = req.body;
      
      if (feePercentage === undefined) {
        return res.status(400).json({ 
          success: false, 
          error: 'feePercentage is required' 
        });
      }

      const result = await this.service.setPlatformFee(feePercentage);
      res.status(result.success ? 200 : 400).json(result);
    } catch (error) {
      const err = error as Error;
      res.status(500).json({ success: false, error: err.message });
    }
  }

  async addSupportedToken(req: Request, res: Response) {
    try {
      const { tokenAddress } = req.body;
      
      if (!tokenAddress) {
        return res.status(400).json({ 
          success: false, 
          error: 'tokenAddress is required' 
        });
      }

      const result = await this.service.addSupportedToken(tokenAddress);
      res.status(result.success ? 200 : 400).json(result);
    } catch (error) {
      const err = error as Error;
      res.status(500).json({ success: false, error: err.message });
    }
  }

  async removeSupportedToken(req: Request, res: Response) {
    try {
      const { tokenAddress } = req.body;
      
      if (!tokenAddress) {
        return res.status(400).json({ 
          success: false, 
          error: 'tokenAddress is required' 
        });
      }

      const result = await this.service.removeSupportedToken(tokenAddress);
      res.status(result.success ? 200 : 400).json(result);
    } catch (error) {
      const err = error as Error;
      res.status(500).json({ success: false, error: err.message });
    }
  }

  async emergencyCloseMarket(req: Request, res: Response) {
    try {
      const { marketId, marketType } = req.body;
      
      if (!marketId || !marketType) {
        return res.status(400).json({ 
          success: false, 
          error: 'marketId and marketType are required' 
        });
      }

      const result = await this.service.emergencyCloseMarket(marketId, marketType);
      res.status(result.success ? 200 : 400).json(result);
    } catch (error) {
      const err = error as Error;
      res.status(500).json({ success: false, error: err.message });
    }
  }

  async emergencyWithdraw(req: Request, res: Response) {
    try {
      const { amount, recipient } = req.body;
      
      if (!amount || !recipient) {
        return res.status(400).json({ 
          success: false, 
          error: 'amount and recipient are required' 
        });
      }

      const result = await this.service.emergencyWithdraw(amount, recipient);
      res.status(result.success ? 200 : 400).json(result);
    } catch (error) {
      const err = error as Error;
      res.status(500).json({ success: false, error: err.message });
    }
  }

  async getAdminState(req: Request, res: Response) {
    try {
      const state = this.stateService.getState();
      res.status(200).json({ success: true, state });
    } catch (error) {
      const err = error as Error;
      res.status(500).json({ success: false, error: err.message });
    }
  }
}

export default AdminController;