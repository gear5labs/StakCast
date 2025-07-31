import { Request, Response } from "express";
import { injectable } from "tsyringe";
import QueueService from "../../../services/queueService";

@injectable()
export default class QueueController {
	constructor(private queueService: QueueService) {}

	async getQueueStats(req: Request, res: Response) {
		try {
			const stats = await this.queueService.getQueueStats();
			res.json(stats);
		} catch (error) {
			res.status(500).json({ error: (error as Error).message });
		}
	}
}
