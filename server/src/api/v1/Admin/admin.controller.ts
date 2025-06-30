import { Request, Response } from "express";
import { injectable } from "tsyringe";
import AdminService from "./admin.service";

@injectable()
export default class AdminController {
	constructor(private adminService: AdminService) {}

	async pauseContract(req: Request, res: Response) {
		try {
			const result = await this.adminService.pauseContract();
			res.json({ success: true, result });
		} catch (error) {
			res.status(400).json({ error: (error as Error).message });
		}
	}

	async unpauseContract(req: Request, res: Response) {
		try {
			const result = await this.adminService.unpauseContract();
			res.json({ success: true, result });
		} catch (error) {
			res.status(400).json({ error: (error as Error).message });
		}
	}

	async setFee(req: Request, res: Response) {
		try {
			const { fee } = req.body;
			const result = await this.adminService.setFee(fee);
			res.json({ success: true, result });
		} catch (error) {
			res.status(400).json({ error: (error as Error).message });
		}
	}

	async addSupportedToken(req: Request, res: Response) {
		try {
			const { tokenAddress } = req.body;
			const result = await this.adminService.addSupportedToken(tokenAddress);
			res.json({ success: true, result });
		} catch (error) {
			res.status(400).json({ error: (error as Error).message });
		}
	}

	async removeSupportedToken(req: Request, res: Response) {
		try {
			const { tokenAddress } = req.body;
			const result = await this.adminService.removeSupportedToken(tokenAddress);
			res.json({ success: true, result });
		} catch (error) {
			res.status(400).json({ error: (error as Error).message });
		}
	}

	async closeMarket(req: Request, res: Response) {
		try {
			const { marketId } = req.body;
			const result = await this.adminService.closeMarket(marketId);
			res.json({ success: true, result });
		} catch (error) {
			res.status(400).json({ error: (error as Error).message });
		}
	}

	async emergencyWithdraw(req: Request, res: Response) {
		try {
			const { to, amount } = req.body;
			const result = await this.adminService.emergencyWithdraw(to, amount);
			res.json({ success: true, result });
		} catch (error) {
			res.status(400).json({ error: (error as Error).message });
		}
	}
}
