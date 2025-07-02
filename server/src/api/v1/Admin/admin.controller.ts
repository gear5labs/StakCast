import { Request, Response } from "express";
import { injectable } from "tsyringe";
import AdminService from "./admin.service";
import { ApplicationError } from "../../../utils/errorHandler";

@injectable()
export default class AdminController {
	constructor(private adminService: AdminService) {}

	pauseContract = async (req: Request, res: Response) => {
		const result = await this.adminService.pauseContract();
		res.json({ success: true, result });
	};

	unpauseContract = async (req: Request, res: Response) => {
		const result = await this.adminService.unpauseContract();
		res.json({ success: true, result });
	};

	setFee = async (req: Request, res: Response) => {
		const { fee } = req.body;
		if (!fee) throw new ApplicationError("Fee is required", 400);
		const result = await this.adminService.setFee(fee);
		res.json({ success: true, result });
	};

	addSupportedToken = async (req: Request, res: Response) => {
		const { tokenAddress } = req.body;
		if (!tokenAddress) throw new ApplicationError("Token address is required", 400);
		const result = await this.adminService.addSupportedToken(tokenAddress);
		res.json({ success: true, result });
	};

	removeSupportedToken = async (req: Request, res: Response) => {
		const { tokenAddress } = req.body;
		if (!tokenAddress) throw new ApplicationError("Token address is required", 400);
		const result = await this.adminService.removeSupportedToken(tokenAddress);
		res.json({ success: true, result });
	};

	closeMarket = async (req: Request, res: Response) => {
		const { marketId } = req.body;
		if (!marketId) throw new ApplicationError("Market ID is required", 400);
		const result = await this.adminService.closeMarket(marketId);
		res.json({ success: true, result });
	};

	emergencyWithdraw = async (req: Request, res: Response) => {
		const { to, amount } = req.body;
		if (!to || !amount) throw new ApplicationError("To and amount are required", 400);
		const result = await this.adminService.emergencyWithdraw(to, amount);
		res.json({ success: true, result });
	};
}
