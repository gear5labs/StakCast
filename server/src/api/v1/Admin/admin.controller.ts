// lib/admin/controllers/admin.controller.ts
import { Request, Response } from 'express';
import AdminService from './admin.service';
import AdminStateService from './adminState.service';

class AdminController {
  private static service = AdminService.getInstance();

  static async pauseContract(req: Request, res: Response) {
    try {
      const result = await AdminController.service.pauseContract();
      res.status(result.success ? 200 : 400).json(result);
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async unpauseContract(req: Request, res: Response) {
    try {
      const result = await AdminController.service.unpauseContract();
      res.status(result.success ? 200 : 400).json(result);
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async setPlatformFee(req: Request, res: Response) {
    try {
      const { feePercentage } = req.body;
      
      if (feePercentage === undefined) {
        return res.status(400).json({ 
          success: false, 
          error: 'feePercentage is required' 
        });
      }

      const result = await AdminController.service.setPlatformFee(feePercentage);
      res.status(result.success ? 200 : 400).json(result);
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async addSupportedToken(req: Request, res: Response) {
    try {
      const { tokenAddress } = req.body;
      
      if (!tokenAddress) {
        return res.status(400).json({ 
          success: false, 
          error: 'tokenAddress is required' 
        });
      }

      const result = await AdminController.service.addSupportedToken(tokenAddress);
      res.status(result.success ? 200 : 400).json(result);
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async removeSupportedToken(req: Request, res: Response) {
    try {
      const { tokenAddress } = req.body;
      
      if (!tokenAddress) {
        return res.status(400).json({ 
          success: false, 
          error: 'tokenAddress is required' 
        });
      }

      const result = await AdminController.service.removeSupportedToken(tokenAddress);
      res.status(result.success ? 200 : 400).json(result);
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async emergencyCloseMarket(req: Request, res: Response) {
    try {
      const { marketId, marketType } = req.body;
      
      if (!marketId || !marketType) {
        return res.status(400).json({ 
          success: false, 
          error: 'marketId and marketType are required' 
        });
      }

      const result = await AdminController.service.emergencyCloseMarket(marketId, marketType);
      res.status(result.success ? 200 : 400).json(result);
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  static async emergencyWithdraw(req: Request, res: Response) {
    try {
      const { amount, recipient } = req.body;
      
      if (!amount || !recipient) {
        return res.status(400).json({ 
          success: false, 
          error: 'amount and recipient are required' 
        });
      }

      const result = await AdminController.service.emergencyWithdraw(amount, recipient);
      res.status(result.success ? 200 : 400).json(result);
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  }
static async getAdminState(req: Request, res: Response) {
    try {
      const state = AdminStateService.getInstance().getState();
      res.status(200).json({ success: true, state });
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  }
}

export default AdminController;